import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student.dart';

/// Error with a message that is safe to show to the student.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode = 0});

  final String message;

  /// HTTP status, or 0 when the server could not be reached.
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

/// Where the backend lives.
///
/// * `--dart-define=API_BASE_URL=http://192.168.1.20:8000` always wins.
/// * On the web it uses the same host the page was opened from, so a phone
///   that opens `http://<pc-ip>:8090` talks to `http://<pc-ip>:8000`.
/// * The Android emulator reaches the PC through 10.0.2.2.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:8000';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

/// Backend operations used by the app. Tests swap in a fake.
abstract class CampusApi {
  Future<(String token, ProfileBundle profile)> register(RegistrationData data);
  Future<(String token, ProfileBundle profile)> login(String identifier, String password);
  Future<void> logout(String token);
  Future<ProfileBundle> fetchProfile(String token);
  Future<ProfileBundle> updateProfile(String token, Map<String, dynamic> changes);
  Future<void> updatePreferences(String token, NotificationPreferences prefs);

  /// Adds/removes an id in one of the student's lists and returns the new list.
  /// [collection] is one of: events, clubs, announcements-read,
  /// library-renewals, shuttle-alerts.
  Future<Set<String>> setItem(String token, String collection, String id, {required bool add});
  Future<Set<String>> markAllRead(String token, Iterable<String> ids);
  Future<HelpdeskTicket> createTicket(String token, TicketRequest request);

  /// Uploads a profile photo (raw image bytes) and returns the new profile.
  Future<ProfileBundle> uploadPhoto(String token, List<int> bytes);
  Future<ProfileBundle> deletePhoto(String token);

  /// Walking path between two points as [lat, lon] pairs, or throws if the
  /// server has no routing key configured.
  Future<WalkingRoute> walkingRoute(double fromLat, double fromLon, double toLat, double toLon);

  /// Absolute URL for a server media path such as /media/abc.jpg.
  String mediaUrl(String path);
}

class WalkingRoute {
  const WalkingRoute({required this.points, this.distanceMetres, this.durationSeconds});

  final List<(double, double)> points;
  final double? distanceMetres;
  final double? durationSeconds;
}

class HttpCampusApi implements CampusApi {
  HttpCampusApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? resolveApiBaseUrl(),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 12);

  @override
  Future<(String, ProfileBundle)> register(RegistrationData data) async {
    final json = await _send('POST', '/api/auth/register', body: data.toJson());
    return _session(json);
  }

  @override
  Future<(String, ProfileBundle)> login(String identifier, String password) async {
    final json = await _send('POST', '/api/auth/login', body: {
      'identifier': identifier,
      'password': password,
    });
    return _session(json);
  }

  @override
  Future<void> logout(String token) => _send('POST', '/api/auth/logout', token: token);

  @override
  Future<ProfileBundle> fetchProfile(String token) async =>
      ProfileBundle.fromJson(await _send('GET', '/api/me', token: token));

  @override
  Future<ProfileBundle> updateProfile(String token, Map<String, dynamic> changes) async =>
      ProfileBundle.fromJson(
        await _send('PATCH', '/api/me', token: token, body: changes),
      );

  @override
  Future<void> updatePreferences(String token, NotificationPreferences prefs) =>
      _send('PUT', '/api/me/preferences', token: token, body: prefs.toJson());

  @override
  Future<Set<String>> setItem(
    String token,
    String collection,
    String id, {
    required bool add,
  }) async {
    final json = await _send(
      add ? 'PUT' : 'DELETE',
      '/api/me/$collection/${Uri.encodeComponent(id)}',
      token: token,
    );
    return _ids(json);
  }

  @override
  Future<Set<String>> markAllRead(String token, Iterable<String> ids) async {
    final json = await _send(
      'POST',
      '/api/me/announcements-read',
      token: token,
      body: {'ids': ids.toList()},
    );
    return _ids(json);
  }

  @override
  Future<HelpdeskTicket> createTicket(String token, TicketRequest request) async =>
      HelpdeskTicket.fromJson(await _send('POST', '/api/me/tickets', token: token, body: request.toJson()));

  @override
  Future<ProfileBundle> uploadPhoto(String token, List<int> bytes) async => ProfileBundle.fromJson(
        await _send('PUT', '/api/me/photo', token: token, body: {'data': base64Encode(bytes)}),
      );

  @override
  Future<ProfileBundle> deletePhoto(String token) async =>
      ProfileBundle.fromJson(await _send('DELETE', '/api/me/photo', token: token));

  @override
  Future<WalkingRoute> walkingRoute(double fromLat, double fromLon, double toLat, double toLon) async {
    final json = await _send('GET', '/api/route/walking?start=$fromLat,$fromLon&end=$toLat,$toLon');
    return WalkingRoute(
      points: [
        for (final p in (json['points'] as List<dynamic>).cast<List<dynamic>>())
          ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ],
      distanceMetres: (json['distance_m'] as num?)?.toDouble(),
      durationSeconds: (json['duration_s'] as num?)?.toDouble(),
    );
  }

  @override
  String mediaUrl(String path) => '$baseUrl$path';

  (String, ProfileBundle) _session(dynamic json) => (
        json['token'] as String,
        ProfileBundle.fromJson(json['profile'] as Map<String, dynamic>),
      );

  Set<String> _ids(dynamic json) =>
      (json['items'] as List<dynamic>).map((e) => e as String).toSet();

  Future<dynamic> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('The server at $baseUrl took too long to respond.');
    } catch (_) {
      throw ApiException(
        "Can't reach the server at $baseUrl. Make sure the backend is running.",
      );
    }

    final text = response.body;
    final dynamic json = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    throw ApiException(_errorMessage(json), statusCode: response.statusCode);
  }

  static String _errorMessage(dynamic json) {
    final detail = json is Map ? json['detail'] : null;
    if (detail is String) return detail;
    // FastAPI validation errors: [{"loc": [...], "msg": "..."}]
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final msg = (detail.first as Map)['msg']?.toString() ?? 'Invalid input';
      return msg.replaceFirst('Value error, ', '');
    }
    return 'Something went wrong. Please try again.';
  }
}
