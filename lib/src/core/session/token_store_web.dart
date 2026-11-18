import 'package:web/web.dart' as web;

class TokenStore {
  static const _refreshKey = 'tooapp_admin_refresh_token';

  Future<(String?, String?)> read() async =>
      (null, web.window.sessionStorage.getItem(_refreshKey));

  Future<void> write(String refreshToken) async {
    web.window.sessionStorage.setItem(_refreshKey, refreshToken);
  }

  Future<void> clear() async {
    web.window.sessionStorage.removeItem(_refreshKey);
  }
}
