import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class AdminSession extends ChangeNotifier {
  AdminSession(this._api) {
    _api.onSessionExpired = expire;
  }

  final ApiClient _api;
  String? _displayName;
  String? _error;
  bool _checking = true;
  bool _busy = false;

  bool get isChecking => _checking;
  bool get isBusy => _busy;
  bool get isAuthenticated => _api.accessToken != null;
  String? get displayName => _displayName;
  String? get error => _error;

  // Kept for existing feature call sites. The JWT API uses Bearer auth and
  // does not require a CSRF token.
  String? get csrfToken => null;

  Future<void> restore() async {
    _checking = true;
    notifyListeners();
    try {
      final hasSession = await _api.restoreSession();
      if (!hasSession) {
        _displayName = null;
        return;
      }
      // The API has no session endpoint. The refresh response validates the
      // saved refresh token; the name is filled after the next login.
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.postData(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );
      final access = data['accessToken'];
      final refresh = data['refreshToken'];
      final user = data['user'];
      if (access is! String ||
          refresh is! String ||
          user is! Map<String, Object?>) {
        throw const ApiFailure(
          null,
          'La respuesta de autenticación no tiene el formato esperado.',
        );
      }
      await _api.setTokens(accessToken: access, refreshToken: refresh);
      if (user['role'] != 'ADMIN') {
        await _api.logout(refreshToken: refresh);
        _api.clearTokens();
        throw const ApiFailure(
          403,
          'Esta cuenta no tiene acceso administrativo.',
        );
      }
      _displayName = _formatDisplayName(user);
      return true;
    } on ApiFailure catch (failure) {
      _error = failure.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final refresh = _api.refreshToken;
    _error = null;
    try {
      if (refresh != null) await _api.logout(refreshToken: refresh);
    } on ApiFailure catch (failure) {
      _error = failure.message;
    } finally {
      _clear();
      notifyListeners();
    }
  }

  void expire() {
    _clear();
    notifyListeners();
  }

  String _formatDisplayName(Map<String, Object?> user) => [
    user['firstName'],
    user['lastName'],
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  void _clear() {
    _api.clearTokens();
    _displayName = null;
  }
}
