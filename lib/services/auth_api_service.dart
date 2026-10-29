import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthApiResult {
  const AuthApiResult({
    required this.success,
    required this.code,
    required this.message,
    this.statusCode,
    this.dioType,
    this.data = const <String, dynamic>{},
  });

  final bool success;
  final String code;
  final String message;
  final int? statusCode;
  final DioExceptionType? dioType;
  final Map<String, dynamic> data;
}

class AuthApiService {
  AuthApiService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status != null && status < 500,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  static String get _lang => AppLocalizations.isArabic ? 'ar' : 'en';

  static Future<AuthApiResult> login({
    required String identifier,
    required String password,
    required bool rememberMe,
    required String deviceId,
  }) async {
    final normalizedIdentifier = identifier.trim();
    final isEmail = normalizedIdentifier.contains('@');

    return _postForm(
      endpoint: 'client_login',
      url: AppUrls.clientlogin,
      data: {
        'identifier': normalizedIdentifier,
        'phone': isEmail ? '' : normalizedIdentifier,
        'email': isEmail ? normalizedIdentifier : '',
        'password': password,
        'remember_me': rememberMe ? '1' : '0',
        'device_id': deviceId,
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> restoreSession({
    required String rememberToken,
    required String deviceId,
  }) async {
    return _postForm(
      endpoint: 'client_session.restore',
      url: AppUrls.clientSession,
      data: {
        'action': 'restore',
        'remember_token': rememberToken,
        'device_id': deviceId,
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> validateSession({
    required String apiKey,
  }) async {
    return _postForm(
      endpoint: 'client_session.validate',
      url: AppUrls.clientSession,
      data: {
        'action': 'validate',
        'lang': _lang,
      },
      extraHeaders: {'X-API-KEY': apiKey},
    );
  }

  static Future<AuthApiResult> logout({
    required String clientId,
    required String apiKey,
    required String rememberToken,
    required String deviceId,
  }) async {
    return _postForm(
      endpoint: 'client_session.logout',
      url: AppUrls.clientSession,
      data: {
        'action': 'logout',
        'client_id': clientId,
        'remember_token': rememberToken,
        'device_id': deviceId,
        'lang': _lang,
      },
      extraHeaders: {'X-API-KEY': apiKey},
    );
  }

  static Future<AuthApiResult> resendEmailVerification({
    required String identifier,
  }) async {
    return _postForm(
      endpoint: 'client_email_verification.resend',
      url: AppUrls.clientEmailVerification,
      data: {
        'action': 'resend',
        'identifier': identifier.trim().toLowerCase(),
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> verifyEmail({
    required String identifier,
    required String code,
  }) async {
    return _postForm(
      endpoint: 'client_email_verification.verify',
      url: AppUrls.clientEmailVerification,
      data: {
        'action': 'verify',
        'identifier': identifier.trim().toLowerCase(),
        'code': code.trim(),
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> registerClient({
    required String ownerName,
    required String storeName,
    required String phone,
    required String email,
    required String password,
  }) async {
    return _postForm(
      endpoint: 'register_client',
      url: AppUrls.clientregister,
      data: {
        'nclient': ownerName,
        'nstore': storeName,
        'phclient': phone,
        'email': email,
        'passclient': password,
        'lang': _lang,
      },
      extraHeaders: const {
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
  }

  static Future<AuthApiResult> sendResetCode({
    required String identifier,
  }) async {
    return _postForm(
      endpoint: 'client_password_reset.send_code',
      url: AppUrls.clientPasswordReset,
      data: {
        'action': 'send_code',
        'identifier': identifier,
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> verifyResetCode({
    required String identifier,
    required String code,
  }) async {
    return _postForm(
      endpoint: 'client_password_reset.verify_code',
      url: AppUrls.clientPasswordReset,
      data: {
        'action': 'verify_code',
        'identifier': identifier,
        'code': code,
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> resetPassword({
    required String identifier,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    return _postForm(
      endpoint: 'client_password_reset.reset_password',
      url: AppUrls.clientPasswordReset,
      data: {
        'action': 'reset_password',
        'identifier': identifier,
        'code': code,
        'new_password': password,
        'confirm_password': confirmPassword,
        'lang': _lang,
      },
    );
  }

  static Future<AuthApiResult> _postForm({
    required String endpoint,
    required String url,
    required Map<String, dynamic> data,
    Map<String, String>? extraHeaders,
  }) async {
    final lease = RequestIdService.acquire(
      operation: endpoint,
      payload: data,
    );
    try {
      final response = await _dio.post(
        url,
        data: FormData.fromMap(data),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            ...lease.headers(),
            if (extraHeaders != null) ...extraHeaders,
          },
        ),
      );
      lease.complete();

      final payload = _asMap(response.data);
      final success =
          payload['success'] == true || payload['status'] == 'success';
      final message = _pickMessage(payload);
      final code = _pickCode(payload, success);

      return AuthApiResult(
        success: success,
        code: code,
        message: message,
        statusCode: response.statusCode,
        data: payload,
      );
    } on DioException catch (error) {
      lease.complete(
        keepForRetry: error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError,
      );
      _logDioFailure(endpoint, error);
      return AuthApiResult(
        success: false,
        code: _dioErrorCode(error),
        message: _dioErrorMessage(error),
        statusCode: error.response?.statusCode,
        dioType: error.type,
      );
    } catch (_) {
      lease.complete(keepForRetry: true);
      return AuthApiResult(
        success: false,
        code: 'UNEXPECTED_ERROR',
        message: AppLocalizations.isArabic
            ? 'تعذر تنفيذ الطلب حالياً. حاول مرة أخرى.'
            : 'Unable to process the request right now. Please try again.',
      );
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  static String _pickMessage(Map<String, dynamic> payload) {
    final message = payload['message'];
    final messageEn = payload['message_en'];
    final messageAr = payload['message_ar'];

    if (AppLocalizations.isArabic &&
        messageAr is String &&
        messageAr.isNotEmpty) {
      return messageAr;
    }
    if (!AppLocalizations.isArabic &&
        messageEn is String &&
        messageEn.isNotEmpty) {
      return messageEn;
    }
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return AppLocalizations.isArabic
        ? 'تعذر تنفيذ الطلب حالياً. حاول مرة أخرى.'
        : 'Unable to process the request right now. Please try again.';
  }

  static String _pickCode(Map<String, dynamic> payload, bool success) {
    final code = payload['code'];
    if (code is String && code.isNotEmpty) {
      return code;
    }
    return success ? 'SUCCESS' : 'REQUEST_FAILED';
  }

  static void _logDioFailure(String endpoint, DioException error) {
    if (!kDebugMode) {
      return;
    }

    final payload = _asMap(error.response?.data);
    final code = payload['code']?.toString();
    debugPrint(
      '$endpoint failed: type=${error.type.name} '
      'status=${error.response?.statusCode} code=$code',
    );
  }

  static String _dioErrorCode(DioException error) {
    final payload = _asMap(error.response?.data);
    final code = payload['code'];
    if (code is String && code.isNotEmpty) {
      return code;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case DioExceptionType.sendTimeout:
        return 'SEND_TIMEOUT';
      case DioExceptionType.receiveTimeout:
        return 'RECEIVE_TIMEOUT';
      case DioExceptionType.badCertificate:
        return 'BAD_CERTIFICATE';
      case DioExceptionType.badResponse:
        return 'BAD_RESPONSE';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      case DioExceptionType.connectionError:
        return 'CONNECTION_ERROR';
      case DioExceptionType.unknown:
        return 'UNKNOWN_NETWORK_ERROR';
    }
  }

  static String _dioErrorMessage(DioException error) {
    final payload = _asMap(error.response?.data);
    final message = _pickMessage(payload);
    if (payload.isNotEmpty && message.isNotEmpty) {
      return message;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppLocalizations.isArabic
            ? 'انتهت مهلة الاتصال. حاول مرة أخرى.'
            : 'The connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return AppLocalizations.isArabic
            ? 'تعذر الاتصال بالشبكة. تحقق من الإنترنت ثم حاول مرة أخرى.'
            : 'Unable to reach the network. Check your connection and try again.';
      case DioExceptionType.badResponse:
        return AppLocalizations.isArabic
            ? 'تعذر تنفيذ الطلب حالياً.'
            : 'Unable to complete the request right now.';
      case DioExceptionType.cancel:
        return AppLocalizations.isArabic
            ? 'تم إلغاء الطلب.'
            : 'The request was cancelled.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AppLocalizations.isArabic
            ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
            : 'An unexpected error occurred. Please try again.';
    }
  }
}
