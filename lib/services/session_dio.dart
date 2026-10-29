import 'dart:convert';

import 'package:dio/dio.dart';
import 'auth_services.dart';
import 'user_session_state.dart';

/// Only a 401, a 403 refusing the key itself, or the installation-wide License
/// Guard restriction for the current credential can invalidate the account.
Dio sessionDio([BaseOptions? options]) => protectSessionDio(Dio(options));

Dio protectSessionDio(Dio dio) {
  if (dio.interceptors.any((item) => item is _SessionInterceptor)) return dio;
  dio.interceptors.add(_SessionInterceptor());
  return dio;
}

class _SessionInterceptor extends Interceptor {
  static const _generation = 'blockatie.sessionGeneration';
  static const _credential = 'blockatie.sessionCredential';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String? key;
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() == 'x-api-key') key = entry.value?.toString();
    }
    if (key != null && key.isNotEmpty) {
      options.extra[_generation] = UserSessionState.generation;
      options.extra[_credential] = key;
      final session = AuthService.currentSession;
      if (session != null && (!session.isValid || session.apiKey != key)) {
        handler.reject(DioException(
            requestOptions: options, type: DioExceptionType.cancel));
        return;
      }
    }
    handler.next(options);
  }

  /// Backend code for a key the server no longer accepts. Several client
  /// endpoints send it with 403 rather than 401; after a password change
  /// rotated the key it must end the session the same way. Other 403s are
  /// per-request authorization failures and must not sign the client out.
  static const _keyRefusedCode = 'INVALID_API_KEY';
  static const _licenseRestrictedCode = 'LICENSE_RESTRICTED';

  static bool _keyRefused(Response<dynamic>? response) {
    final status = response?.statusCode;
    if (status == 401) return true;
    var body = response?.data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {
        return false;
      }
    }
    if (body is! Map) return false;
    // 423 is intentionally scoped to the signed local License Guard state;
    // it ends a cached mobile session after central suspension is applied.
    if (status == 423 && body['code'] == _licenseRestrictedCode) return true;
    return status == 403 && body['code'] == _keyRefusedCode;
  }

  Future<void> _check(
      Response<dynamic>? response, RequestOptions options) async {
    final key = options.extra[_credential];
    final generation = options.extra[_generation];
    if (_keyRefused(response) && key is String && generation is int) {
      await AuthService.invalidateIfCurrent(key, generation);
    }
  }

  bool _stale(RequestOptions options) =>
      options.extra.containsKey(_generation) &&
      options.extra[_generation] != UserSessionState.generation;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      await _check(response, response.requestOptions);
    } catch (_) {}
    if (_stale(response.requestOptions)) {
      handler.reject(DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel));
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    try {
      await _check(error.response, error.requestOptions);
    } catch (_) {}
    handler.next(error);
  }
}
