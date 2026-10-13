import 'package:crimson_campus/models/student.dart';
import 'package:crimson_campus/services/campus_api.dart';

/// In-memory stand-in for the FastAPI backend so widget tests run offline.
class FakeCampusApi implements CampusApi {
  final Map<String, ({RegistrationData data, Map<String, dynamic> extra})> _accounts = {};
  final Map<String, Set<String>> lists = {};
  final List<HelpdeskTicket> tickets = [];
  NotificationPreferences prefs = NotificationPreferences.defaults;
  String? _currentEmail;

  void seedAccount(RegistrationData data) {
    _accounts[data.email.toLowerCase()] = (data: data, extra: {});
  }

  @override
  Future<(String, ProfileBundle)> register(RegistrationData data) async {
    final key = data.email.toLowerCase();
    final duplicate = _accounts.containsKey(key) ||
        _accounts.values.any((a) => a.data.studentId.toUpperCase() == data.studentId.toUpperCase());
    if (duplicate) {
      throw const ApiException('An account with this email or student ID already exists', statusCode: 409);
    }
    seedAccount(data);
    _currentEmail = key;
    return ('token-$key', _bundle());
  }

  @override
  Future<(String, ProfileBundle)> login(String identifier, String password) async {
    final id = identifier.trim().toLowerCase();
    final match = _accounts.entries.where(
      (e) => e.key == id || e.value.data.studentId.toLowerCase() == id,
    );
    if (match.isEmpty || match.first.value.data.password != password) {
      throw const ApiException('Incorrect email/student ID or password', statusCode: 401);
    }
    _currentEmail = match.first.key;
    return ('token-${match.first.key}', _bundle());
  }

  @override
  Future<void> logout(String token) async => _currentEmail = null;

  @override
  Future<ProfileBundle> fetchProfile(String token) async => _bundle();

  @override
  Future<ProfileBundle> updateProfile(String token, Map<String, dynamic> changes) async {
    _accounts[_currentEmail]!.extra.addAll(changes);
    return _bundle();
  }

  @override
  Future<void> updatePreferences(String token, NotificationPreferences prefs) async {
    this.prefs = prefs;
  }

  @override
  Future<Set<String>> setItem(String token, String collection, String id, {required bool add}) async {
    final set = lists.putIfAbsent(collection, () => <String>{});
    add ? set.add(id) : set.remove(id);
    return {...set};
  }

  @override
  Future<Set<String>> markAllRead(String token, Iterable<String> ids) async {
    final set = lists.putIfAbsent('announcements-read', () => <String>{})..addAll(ids);
    return {...set};
  }

  @override
  Future<HelpdeskTicket> createTicket(String token, String category, String message) async {
    final ticket = HelpdeskTicket(
      ticketNo: 'HD-${1001 + tickets.length}',
      category: category,
      message: message,
      status: 'Open',
      createdAt: '2026-10-07 09:00:00',
    );
    tickets.insert(0, ticket);
    return ticket;
  }

  int photoUploads = 0;

  @override
  Future<ProfileBundle> uploadPhoto(String token, List<int> bytes) async {
    photoUploads++;
    _accounts[_currentEmail]!.extra['photo_url'] = '/media/test-$photoUploads.jpg';
    return _bundle();
  }

  @override
  Future<ProfileBundle> deletePhoto(String token) async {
    _accounts[_currentEmail]!.extra.remove('photo_url');
    return _bundle();
  }

  @override
  Future<WalkingRoute> walkingRoute(double fromLat, double fromLon, double toLat, double toLon) async =>
      throw const ApiException('Walking directions are not configured', statusCode: 503);

  @override
  String mediaUrl(String path) => 'http://localhost:8000$path';

  ProfileBundle _bundle() {
    final account = _accounts[_currentEmail]!;
    final d = account.data;
    final x = account.extra;
    Set<String> list(String name) => {...?lists[name]};
    return ProfileBundle(
      student: Student(
        pk: 1,
        id: d.studentId.toUpperCase(),
        name: (x['full_name'] as String?) ?? d.fullName,
        email: d.email.toLowerCase(),
        programme: (x['programme'] as String?) ?? d.programme,
        semester: (x['semester'] as int?) ?? d.semester,
        totalSemesters: 8,
        cgpa: x.containsKey('cgpa') ? x['cgpa'] as double? : d.cgpa,
        creditsEarned: (x['credits_earned'] as int?) ?? d.creditsEarned,
        creditsRequired: 120,
        advisor: 'To be assigned',
        phone: (x['phone'] as String?) ?? d.phone,
        residence: x['residence'] as String?,
        photoUrl: x['photo_url'] as String?,
      ),
      preferences: prefs,
      registeredEvents: list('events'),
      joinedClubs: list('clubs'),
      readAnnouncements: list('announcements-read'),
      renewedBooks: list('library-renewals'),
      shuttleAlerts: list('shuttle-alerts'),
      tickets: [...tickets],
    );
  }
}

const demoStudent = RegistrationData(
  fullName: 'Nur Aisyah Rahman',
  studentId: 'I23012345',
  email: 'aisyah@student.inti.edu.my',
  password: 'secret123',
  programme: 'BSc (Hons) Computer Science',
  semester: 5,
  cgpa: 3.62,
  creditsEarned: 64,
);
