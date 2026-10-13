import 'token_store_memory.dart'
    if (dart.library.js_interop) 'token_store_web.dart' as impl;

/// Remembers the login token. On the web it survives page refreshes
/// (browser localStorage); elsewhere it lasts for the app session.
class TokenStore {
  const TokenStore._();

  static String? read() => impl.readToken();

  static void write(String? token) => impl.writeToken(token);
}
