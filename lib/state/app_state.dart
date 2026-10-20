import 'dart:async';

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/campus_api.dart';
import '../services/token_store.dart';

/// App-wide state backed by the API.
///
/// Toggles update the UI immediately, then sync with the server; if the
/// server call fails the change is rolled back and the error is rethrown so
/// the page can show it.
class AppState {
  AppState._();

  static final AppState instance = AppState._();

  CampusApi api = HttpCampusApi();

  /// Used to send the student back to the login page if their session expires.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Route to open when the session expires (set by routes.dart).
  String loginRoute = '/login';

  String? _token;

  final ValueNotifier<Student?> student = ValueNotifier<Student?>(null);
  final ValueNotifier<NotificationPreferences> preferences =
      ValueNotifier<NotificationPreferences>(NotificationPreferences.defaults);
  final ValueNotifier<List<HelpdeskTicket>> tickets =
      ValueNotifier<List<HelpdeskTicket>>(const []);

  /// Light / dark look for the landing page and campus map.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Selected tab in the bottom navigation of the home shell.
  final ValueNotifier<int> currentTab = ValueNotifier<int>(0);

  final ValueNotifier<Set<String>> registeredEvents = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> joinedClubs = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> readAnnouncements = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> renewedBooks = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> shuttleAlerts = ValueNotifier(<String>{});

  bool get isLoggedIn => student.value != null;

  /// The logged-in student. Only call on pages behind the login guard.
  Student get me => student.value!;

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  /// Restores a saved login (web keeps it across refreshes).
  Future<void> restoreSession() async {
    final token = TokenStore.read();
    if (token == null) return;
    try {
      final profile = await api.fetchProfile(token).timeout(const Duration(seconds: 6));
      _token = token;
      _apply(profile);
    } on ApiException catch (e) {
      if (e.isUnauthorized) TokenStore.write(null);
    } on TimeoutException {
      // Backend not reachable yet; the student can log in again.
    }
  }

  Future<void> login(String identifier, String password) async {
    final (token, profile) = await api.login(identifier.trim(), password);
    _startSession(token, profile);
  }

  Future<void> register(RegistrationData data) async {
    final (token, profile) = await api.register(data);
    _startSession(token, profile);
  }

  Future<void> logout() async {
    final token = _token;
    _clear();
    if (token != null) {
      try {
        await api.logout(token);
      } on ApiException {
        // Already logged out locally; nothing else to do.
      }
    }
  }

  void _startSession(String token, ProfileBundle profile) {
    _token = token;
    TokenStore.write(token);
    currentTab.value = 0;
    _apply(profile);
  }

  void _apply(ProfileBundle profile) {
    student.value = profile.student;
    preferences.value = profile.preferences;
    tickets.value = profile.tickets;
    registeredEvents.value = profile.registeredEvents;
    joinedClubs.value = profile.joinedClubs;
    readAnnouncements.value = profile.readAnnouncements;
    renewedBooks.value = profile.renewedBooks;
    shuttleAlerts.value = profile.shuttleAlerts;
  }

  void _clear() {
    _token = null;
    TokenStore.write(null);
    student.value = null;
    preferences.value = NotificationPreferences.defaults;
    tickets.value = const [];
    for (final set in [registeredEvents, joinedClubs, readAnnouncements, renewedBooks, shuttleAlerts]) {
      set.value = <String>{};
    }
    currentTab.value = 0;
  }

  /// Runs an authenticated call; on 401 logs out and returns to login.
  Future<T> _authed<T>(Future<T> Function(String token) call) async {
    final token = _token;
    if (token == null) {
      throw const ApiException('Please log in again.', statusCode: 401);
    }
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        _clear();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(loginRoute, (_) => false);
      }
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final profile = await _authed((t) => api.updateProfile(t, changes));
    _apply(profile);
  }

  Future<void> setPreferences(NotificationPreferences next) async {
    final before = preferences.value;
    preferences.value = next;
    try {
      await _authed((t) => api.updatePreferences(t, next));
    } catch (_) {
      preferences.value = before;
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Per-student lists. Each returns true when the item is now in the list.
  // -------------------------------------------------------------------------

  Future<bool> toggleEvent(String id) => _toggle(registeredEvents, 'events', id);

  Future<bool> toggleClub(String id) => _toggle(joinedClubs, 'clubs', id);

  Future<bool> toggleShuttleAlert(String id) => _toggle(shuttleAlerts, 'shuttle-alerts', id);

  Future<void> renewBook(String id) async {
    if (renewedBooks.value.contains(id)) return;
    await _toggle(renewedBooks, 'library-renewals', id);
  }

  Future<void> markRead(String id) async {
    if (readAnnouncements.value.contains(id)) return;
    await _toggle(readAnnouncements, 'announcements-read', id);
  }

  /// For taps that also navigate away: failures just leave it unread.
  void markReadInBackground(String id) {
    markRead(id).catchError((Object _) {});
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final before = readAnnouncements.value;
    readAnnouncements.value = {...before, ...ids};
    try {
      readAnnouncements.value = await _authed((t) => api.markAllRead(t, ids));
    } catch (_) {
      readAnnouncements.value = before;
      rethrow;
    }
  }

  Future<void> uploadPhoto(List<int> bytes) async {
    _apply(await _authed((t) => api.uploadPhoto(t, bytes)));
  }

  Future<void> removePhoto() async {
    _apply(await _authed((t) => api.deletePhoto(t)));
  }

  /// Full URL of the logged-in student's photo, or null.
  String? get photoUrl {
    final path = student.value?.photoUrl;
    return path == null ? null : api.mediaUrl(path);
  }

  Future<HelpdeskTicket> raiseTicket(String category, String message) async {
    final ticket = await _authed((t) => api.createTicket(t, category, message));
    tickets.value = [ticket, ...tickets.value];
    return ticket;
  }

  Future<bool> _toggle(
    ValueNotifier<Set<String>> notifier,
    String collection,
    String id,
  ) async {
    final before = notifier.value;
    final adding = !before.contains(id);
    notifier.value = adding ? {...before, id} : ({...before}..remove(id));
    try {
      notifier.value = await _authed(
        (t) => api.setItem(t, collection, id, add: adding),
      );
      return adding;
    } catch (_) {
      notifier.value = before;
      rethrow;
    }
  }
}
