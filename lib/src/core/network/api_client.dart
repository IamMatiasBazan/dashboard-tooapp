import 'dart:async';

import 'package:dio/dio.dart';

import '../session/token_store.dart';
import 'browser_adapter_stub.dart'
    if (dart.library.js_interop) 'browser_adapter_web.dart'
    as platform_adapter;

class ApiFailure implements Exception {
  const ApiFailure(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
    : dio = dio ?? Dio(),
      _tokenStore = TokenStore() {
    this.dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    platform_adapter.configureBrowserAdapter(this.dio);
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final canRefresh =
              error.response?.statusCode == 401 &&
              _refreshToken != null &&
              error.requestOptions.extra['authRetried'] != true &&
              path != '/auth/login' &&
              path != '/auth/refresh' &&
              path != '/auth/logout';
          if (!canRefresh) return handler.next(error);

          try {
            await _refreshTokens();
            final options = error.requestOptions
              ..extra['authRetried'] = true
              ..headers['Authorization'] = 'Bearer $_accessToken';
            handler.resolve(await this.dio.fetch<Object?>(options));
          } on Object {
            clearTokens();
            onSessionExpired?.call();
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio dio;
  final TokenStore _tokenStore;
  String? _accessToken;
  String? _refreshToken;
  Future<void>? _refreshing;

  void Function()? onSessionExpired;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _tokenStore.write(refreshToken);
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    unawaited(_tokenStore.clear());
  }

  Future<bool> restoreSession() async {
    final (_, refreshToken) = await _tokenStore.read();
    if (refreshToken == null) {
      clearTokens();
      return false;
    }
    _accessToken = null;
    _refreshToken = refreshToken;
    try {
      await _refreshTokens();
      return true;
    } on Object {
      clearTokens();
      return false;
    }
  }

  Future<Map<String, Object?>> getData(
    String path, {
    Map<String, Object?>? query,
  }) async {
    try {
      final response = await dio.get<Object?>(path, queryParameters: query);
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<List<Map<String, Object?>>> getList(
    String path, {
    Map<String, Object?>? query,
  }) async {
    try {
      final response = await dio.get<Object?>(path, queryParameters: query);
      final body = response.data;
      if (body is Map<String, Object?> && body['data'] is List<Object?>) {
        return (body['data']! as List<Object?>)
            .whereType<Map<String, Object?>>()
            .toList(growable: false);
      }
      if (body is Map<String, Object?> &&
          body['data'] is Map<String, Object?>) {
        final data = body['data']! as Map<String, Object?>;
        if (data['items'] is List<Object?>) {
          return (data['items']! as List<Object?>)
              .whereType<Map<String, Object?>>()
              .toList(growable: false);
        }
      }
      throw const ApiFailure(
        null,
        'La respuesta del servidor no tiene el formato esperado.',
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<Map<String, Object?>> patchPath(
    String path, {
    String? csrfToken,
  }) async {
    try {
      final response = await dio.patch<Object?>(
        path,
        options: Options(
          headers: csrfToken == null ? null : {'X-CSRF-Token': csrfToken},
        ),
      );
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<Map<String, Object?>> postData(
    String path, {
    Object? body,
    String? csrfToken,
  }) async {
    try {
      final response = await dio.post<Object?>(
        path,
        data: body,
        options: Options(
          headers: csrfToken == null ? null : {'X-CSRF-Token': csrfToken},
        ),
      );
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> postVoid(String path, {String? csrfToken}) async {
    try {
      await dio.post<void>(
        path,
        options: Options(
          headers: csrfToken == null ? null : {'X-CSRF-Token': csrfToken},
        ),
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      await dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> _refreshTokens() {
    final current = _refreshing;
    if (current != null) return current;
    final refresh = _performRefresh();
    _refreshing = refresh;
    return refresh.whenComplete(() {
      _refreshing = null;
    });
  }

  Future<void> _performRefresh() async {
    final currentRefreshToken = _refreshToken;
    if (currentRefreshToken == null) {
      throw const ApiFailure(401, 'La sesión venció. Iniciá sesión nuevamente.');
    }
    try {
      final response = await dio.post<Object?>(
        '/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
      );
      final tokens = _dataMap(response.data);
      final access = tokens['accessToken'];
      final refresh = tokens['refreshToken'];
      if (access is! String || refresh is! String) {
        throw const ApiFailure(
          null,
          'La respuesta de sesión no tiene el formato esperado.',
        );
      }
      await setTokens(accessToken: access, refreshToken: refresh);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<Map<String, Object?>> patchData(
    String path, {
    Object? body,
    String? csrfToken,
  }) async {
    try {
      final response = await dio.patch<Object?>(
        path,
        data: body,
        options: Options(
          headers: csrfToken == null ? null : {'X-CSRF-Token': csrfToken},
        ),
      );
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Map<String, Object?> _dataMap(Object? responseData) {
    if (responseData is Map<String, Object?> &&
        responseData['data'] is Map<String, Object?>) {
      return responseData['data']! as Map<String, Object?>;
    }
    throw const ApiFailure(
      null,
      'La respuesta del servidor no tiene el formato esperado.',
    );
  }

  ApiFailure _failure(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, Object?>) {
      final errorBody = data['error'];
      if (errorBody is Map<String, Object?> && errorBody['message'] is String) {
        return ApiFailure(status, errorBody['message']! as String);
      }
      if (data['message'] is String) {
        return ApiFailure(status, data['message']! as String);
      }
    }
    return ApiFailure(status, switch (status) {
      401 => 'La sesión venció. Iniciá sesión nuevamente.',
      403 => 'No tenés permiso para realizar esta acción.',
      409 => 'El registro cambió. Actualizá la información e intentá de nuevo.',
      _ => 'No se pudo completar la solicitud. Verificá tu conexión e intentá nuevamente.',
    });
  }
}
