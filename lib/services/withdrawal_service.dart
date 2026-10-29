import 'package:blockatie/services/session_dio.dart';
import 'dart:convert';
import 'dart:math';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WithdrawalService {
  WithdrawalService._();

  static final Dio _dio = sessionDio();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Persist the same identifier across timeouts and restarts, scoped to the
  // authenticated account. Details remain in encrypted storage until resolved.
  static Future<String> _requestKey(
    String clientId,
    String amount,
    String method,
    String details,
  ) async {
    final storageKey = 'wallet_withdrawal_attempt_$clientId';
    final intent = jsonEncode([amount, method, details]);
    final saved = await _storage.read(key: storageKey);
    if (saved != null) {
      final previous = jsonDecode(saved);
      if (previous is Map &&
          previous['intent'] == intent &&
          previous['key'] is String) {
        return previous['key'] as String;
      }
    }
    final random = Random.secure();
    final key = List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    await _storage.write(
      key: storageKey,
      value: jsonEncode({'intent': intent, 'key': key}),
    );
    return key;
  }

  static Future<Map<String, dynamic>> addWithdrawalRequest({
    required String amount,
    required String withdrawalMethod,
    String accountDetails = '',
  }) async {
    try {
      final apiKey = await AuthService.getApiKey();
      final clientId = await AuthService.getUserId();

      if (apiKey == null ||
          apiKey.trim().isEmpty ||
          clientId == null ||
          clientId.trim().isEmpty) {
        return {
          'success': false,
          'message': _text(
            'Authentication credentials not found. Please login again.',
            'بيانات تسجيل الدخول غير متوفرة. يرجى تسجيل الدخول مرة أخرى.',
          ),
          'data': const <String, dynamic>{},
        };
      }

      final requestKey = await _requestKey(
        clientId,
        amount,
        withdrawalMethod,
        accountDetails.trim(),
      );
      final response = await _dio.post(
        AppUrls.clientAddWithdrawalRequest,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
            'Idempotency-Key': requestKey,
          },
        ),
        data: {
          'driver_id': '0',
          'client_id': clientId,
          'amount': amount,
          'withdrawal_method': withdrawalMethod,
          if (accountDetails.trim().isNotEmpty)
            'account_details': accountDetails,
        },
      );

      if (kDebugMode) {
        debugPrint('Create withdrawal status: ${response.statusCode}');
      }

      final data = _asMap(response.data);
      final success = data['success'] == true ||
          data['status'] == 'success' ||
          data['code'] == 'CREATE_SUCCESS';

      if (success) {
        // A local cleanup error cannot turn an acknowledged payout request
        // into a failure. Reusing its key is safe if cleanup must be retried.
        try {
          await _storage.delete(key: 'wallet_withdrawal_attempt_$clientId');
        } catch (_) {}
      }

      return {
        'success': success,
        'message': _messageFrom(
          data,
          fallback: success
              ? _text(
                  'Withdrawal request submitted successfully.',
                  'تم إرسال طلب السحب بنجاح.',
                )
              : _text(
                  'Failed to send withdrawal request.',
                  'تعذر إرسال طلب السحب.',
                ),
        ),
        'code': data['code']?.toString(),
        'data': data,
      };
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
            'Create withdrawal Dio status: ${error.response?.statusCode}');
      }

      final data = _asMap(error.response?.data);
      return {
        'success': false,
        'message': _messageFrom(
          data,
          fallback: _text(
            'Unable to send withdrawal request. Please try again.',
            'تعذر إرسال طلب السحب. حاول مرة أخرى.',
          ),
        ),
        'code': data['code']?.toString(),
        'data': data,
      };
    } catch (_) {
      return {
        'success': false,
        'message': _text(
          'Unable to send withdrawal request. Please try again.',
          'تعذر إرسال طلب السحب. حاول مرة أخرى.',
        ),
        'data': const <String, dynamic>{},
      };
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static String _messageFrom(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final preferredKey =
        AppLocalizations.isArabic ? 'message_ar' : 'message_en';
    final fallbackKey = AppLocalizations.isArabic ? 'message_en' : 'message_ar';

    for (final key in <String>[preferredKey, 'message', fallbackKey]) {
      final text = data[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static String _text(String en, String ar) =>
      AppLocalizations.isArabic ? ar : en;
}
