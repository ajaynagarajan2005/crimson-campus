import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

import '../models/student.dart';
import 'campus_api.dart';

/// Campus data stored in Firebase:
///   * Authentication (email + password) for accounts
///   * Firestore `students/{uid}` for the profile and everything the student
///     saves, `students/{uid}/tickets` for helpdesk tickets
///   * Firestore `studentIds/{STUDENT_ID}` so students can log in with their ID
///
/// Profile photos are resized in the browser and stored in the student
/// document, which keeps the project on Firebase's free plan.
class FirebaseCampusApi implements CampusApi {
  FirebaseCampusApi({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _collections = {
    'events': 'registered_events',
    'clubs': 'joined_clubs',
    'announcements-read': 'read_announcements',
    'library-renewals': 'renewed_books',
    'shuttle-alerts': 'shuttle_alerts',
  };

  CollectionReference<Map<String, dynamic>> get _students => _db.collection('students');

  // -------------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------------

  @override
  Future<(String, ProfileBundle)> register(RegistrationData data) async {
    final studentId = data.studentId.trim().toUpperCase();
    final email = data.email.trim().toLowerCase();
    final idRef = _db.collection('studentIds').doc(studentId);

    final existing = await _guard(() => idRef.get());
    if (existing.exists) {
      throw const ApiException('An account with this email or student ID already exists', statusCode: 409);
    }

    final cred = await _guard(() => _auth.createUserWithEmailAndPassword(email: email, password: data.password));
    final uid = cred.user!.uid;
    try {
      await _guard(
        () => _db.runTransaction((tx) async {
          final taken = await tx.get(idRef);
          if (taken.exists) {
            throw const ApiException('An account with this email or student ID already exists', statusCode: 409);
          }
          tx.set(idRef, {'uid': uid, 'email': email});
          tx.set(_students.doc(uid), {
            'student_id': studentId,
            'full_name': data.fullName.trim(),
            'email': email,
            'programme': data.programme.trim(),
            'semester': data.semester,
            'total_semesters': 8,
            'cgpa': data.cgpa,
            'credits_earned': data.creditsEarned,
            'credits_required': 120,
            'phone': (data.phone?.isEmpty ?? true) ? null : data.phone,
            'residence': null,
            'advisor': 'To be assigned',
            'photo_data': null,
            'preferences': {'announcements': true, 'class_reminders': true, 'shuttle_alerts': false},
            for (final field in _collections.values) field: <String>[],
            'created_at': FieldValue.serverTimestamp(),
          });
        }),
      );
    } catch (_) {
      // Don't leave an auth account without a profile behind.
      await cred.user?.delete();
      rethrow;
    }
    return (uid, await fetchProfile(uid));
  }

  @override
  Future<(String, ProfileBundle)> login(String identifier, String password) async {
    var email = identifier.trim().toLowerCase();
    if (!email.contains('@')) {
      // Student ID: look up the email it belongs to.
      final doc = await _guard(() => _db.collection('studentIds').doc(identifier.trim().toUpperCase()).get());
      if (!doc.exists) throw _wrongCredentials;
      email = doc.data()!['email'] as String;
    }
    final cred = await _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));
    return (cred.user!.uid, await fetchProfile(cred.user!.uid));
  }

  @override
  Future<void> logout(String token) => _auth.signOut();

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  @override
  Future<ProfileBundle> fetchProfile(String token) async {
    final user = await _currentUser();
    final doc = await _guard(() => _students.doc(user.uid).get());
    if (!doc.exists) throw const ApiException('Your profile was not found. Please create an account.', statusCode: 401);
    final tickets = await _guard(
      () => _students.doc(user.uid).collection('tickets').orderBy('created_at', descending: true).get(),
    );
    return _bundle(user.uid, doc.data()!, tickets.docs);
  }

  @override
  Future<ProfileBundle> updateProfile(String token, Map<String, dynamic> changes) async {
    final user = await _currentUser();
    const allowed = {'full_name', 'programme', 'semester', 'cgpa', 'credits_earned', 'phone', 'residence'};
    final update = <String, dynamic>{
      for (final entry in changes.entries)
        if (allowed.contains(entry.key))
          entry.key: entry.value is String && (entry.value as String).trim().isEmpty ? null : entry.value,
    };
    await _guard(() => _students.doc(user.uid).update(update));
    return fetchProfile(token);
  }

  @override
  Future<void> updatePreferences(String token, NotificationPreferences prefs) async {
    final user = await _currentUser();
    await _guard(() => _students.doc(user.uid).update({'preferences': prefs.toJson()}));
  }

  @override
  Future<Set<String>> setItem(String token, String collection, String id, {required bool add}) async {
    final field = _collections[collection];
    if (field == null) throw const ApiException('Unknown collection', statusCode: 404);
    final user = await _currentUser();
    final ref = _students.doc(user.uid);
    await _guard(() => ref.update({field: add ? FieldValue.arrayUnion([id]) : FieldValue.arrayRemove([id])}));
    final doc = await _guard(() => ref.get());
    return _ids(doc.data()?[field]);
  }

  @override
  Future<Set<String>> markAllRead(String token, Iterable<String> ids) async {
    final user = await _currentUser();
    final ref = _students.doc(user.uid);
    await _guard(() => ref.update({'read_announcements': FieldValue.arrayUnion(ids.toList())}));
    final doc = await _guard(() => ref.get());
    return _ids(doc.data()?['read_announcements']);
  }

  @override
  Future<HelpdeskTicket> createTicket(String token, String category, String message) async {
    final user = await _currentUser();
    final ticketNo = 'HD-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final now = DateTime.now().toUtc();
    await _guard(
      () => _students.doc(user.uid).collection('tickets').add({
        'ticket_no': ticketNo,
        'category': category,
        'message': message.trim(),
        'status': 'Open',
        'created_at': Timestamp.fromDate(now),
      }),
    );
    return HelpdeskTicket(
      ticketNo: ticketNo,
      category: category,
      message: message.trim(),
      status: 'Open',
      createdAt: _formatTime(now),
    );
  }

  // -------------------------------------------------------------------------
  // Photo: square 512 px JPEG stored as a data URL in the student document.
  // -------------------------------------------------------------------------

  @override
  Future<ProfileBundle> uploadPhoto(String token, List<int> bytes) async {
    final user = await _currentUser();
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const ApiException('Please choose a JPEG, PNG or WebP image', statusCode: 422);
    }
    final square = img.copyResizeCropSquare(img.bakeOrientation(decoded), size: 512);
    final jpeg = img.encodeJpg(square, quality: 82);
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(jpeg)}';
    await _guard(() => _students.doc(user.uid).update({'photo_data': dataUrl}));
    return fetchProfile(token);
  }

  @override
  Future<ProfileBundle> deletePhoto(String token) async {
    final user = await _currentUser();
    await _guard(() => _students.doc(user.uid).update({'photo_data': null}));
    return fetchProfile(token);
  }

  /// No routing server in the Firebase build: the map falls back to a
  /// straight-line guide and the Google Maps hand-off.
  @override
  Future<WalkingRoute> walkingRoute(double fromLat, double fromLon, double toLat, double toLon) async =>
      throw const ApiException('Walking directions are not configured', statusCode: 503);

  @override
  String mediaUrl(String path) => path; // photos are already data URLs

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static const _wrongCredentials = ApiException('Incorrect email/student ID or password', statusCode: 401);

  Future<User> _currentUser() async {
    final user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user == null) throw const ApiException('Please log in again.', statusCode: 401);
    return user;
  }

  Set<String> _ids(dynamic value) => {for (final v in (value as List<dynamic>? ?? const [])) v as String};

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  ProfileBundle _bundle(
    String uid,
    Map<String, dynamic> d,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tickets,
  ) {
    final prefs = (d['preferences'] as Map<String, dynamic>?) ?? const {};
    return ProfileBundle(
      student: Student(
        pk: uid.hashCode,
        id: d['student_id'] as String,
        name: d['full_name'] as String,
        email: d['email'] as String,
        programme: d['programme'] as String,
        semester: (d['semester'] as num).toInt(),
        totalSemesters: (d['total_semesters'] as num? ?? 8).toInt(),
        cgpa: (d['cgpa'] as num?)?.toDouble(),
        creditsEarned: (d['credits_earned'] as num? ?? 0).toInt(),
        creditsRequired: (d['credits_required'] as num? ?? 120).toInt(),
        advisor: (d['advisor'] as String?) ?? 'To be assigned',
        phone: d['phone'] as String?,
        residence: d['residence'] as String?,
        photoUrl: d['photo_data'] as String?,
      ),
      preferences: NotificationPreferences(
        announcements: prefs['announcements'] as bool? ?? true,
        classReminders: prefs['class_reminders'] as bool? ?? true,
        shuttleAlerts: prefs['shuttle_alerts'] as bool? ?? false,
      ),
      registeredEvents: _ids(d['registered_events']),
      joinedClubs: _ids(d['joined_clubs']),
      readAnnouncements: _ids(d['read_announcements']),
      renewedBooks: _ids(d['renewed_books']),
      shuttleAlerts: _ids(d['shuttle_alerts']),
      tickets: [
        for (final t in tickets)
          HelpdeskTicket(
            ticketNo: t['ticket_no'] as String,
            category: t['category'] as String,
            message: t['message'] as String,
            status: t['status'] as String,
            createdAt: _formatTime((t['created_at'] as Timestamp).toDate().toUtc()),
          ),
      ],
    );
  }

  /// Turns Firebase errors into messages a student can act on.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' => _wrongCredentials,
        'email-already-in-use' =>
          const ApiException('An account with this email or student ID already exists', statusCode: 409),
        'weak-password' => const ApiException('Use a stronger password (at least 6 characters)', statusCode: 422),
        'network-request-failed' => const ApiException("Can't reach Firebase. Check your internet connection."),
        'operation-not-allowed' || 'configuration-not-found' || 'internal-error' => const ApiException(
            'Sign-in is not set up yet: enable Email/Password in the Firebase console (Authentication).',
            statusCode: 503,
          ),
        'too-many-requests' => const ApiException('Too many attempts. Please wait a minute and try again.', statusCode: 429),
        _ => ApiException(e.message ?? 'Sign-in failed. Please try again.', statusCode: 400),
      };
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => const ApiException('You do not have access to that data.', statusCode: 403),
        'not-found' || 'failed-precondition' => const ApiException(
            'The campus database is not set up yet: create the Firestore database in the Firebase console.',
            statusCode: 503,
          ),
        'unavailable' => const ApiException("Can't reach Firebase. Check your internet connection."),
        _ => ApiException(e.message ?? 'Something went wrong. Please try again.', statusCode: 500),
      };
    }
  }
}
