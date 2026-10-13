import 'package:web/web.dart' as web;

const _key = 'crimson_campus_token';

String? readToken() {
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    return null; // storage blocked (e.g. private mode)
  }
}

void writeToken(String? token) {
  try {
    if (token == null) {
      web.window.localStorage.removeItem(_key);
    } else {
      web.window.localStorage.setItem(_key, token);
    }
  } catch (_) {
    // Storage unavailable: the session simply won't survive a refresh.
  }
}
