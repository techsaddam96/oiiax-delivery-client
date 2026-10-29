import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WithdrawalRequest {
  final int id;
  final int clientId;
  final String amount;
  final String currency;
  final int status;
  final String withdrawalMethod;
  final String accountDetails;
  final String requestedAt;

  WithdrawalRequest({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.withdrawalMethod,
    required this.accountDetails,
    required this.requestedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: _asInt(json['id']),
      clientId: _asInt(json['client_id']),
      amount: _asAmountString(json['amount']),
      currency: (json['currency']?.toString().trim().isNotEmpty ?? false)
          ? json['currency'].toString().trim()
          : 'JOD',
      status: _asInt(json['status']),
      withdrawalMethod: json['withdrawal_method']?.toString().trim() ?? '',
      accountDetails: json['account_details']?.toString().trim() ?? '',
      requestedAt: json['requested_at']?.toString().trim() ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      case 2:
        return 'Rejected';
      case 3:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 0:
        return const Color(0xffF59E0B);
      case 1:
        return const Color(0xff0EA5E9);
      case 2:
        return const Color(0xffDC2626);
      case 3:
        return const Color(0xff16A34A);
      default:
        return const Color(0xff64748B);
    }
  }
}

class RequestsService {
  RequestsService._();

  static final Dio _dio = sessionDio();

  static Future<Map<String, dynamic>> fetchWithdrawalRequests() async {
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
          'requests': const <WithdrawalRequest>[],
        };
      }

      final response = await _dio.post(
        AppUrls.clientWithdrawalRequests,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
        data: {
          'client_id': clientId,
        },
      );

      if (kDebugMode) {
        debugPrint('Wallet requests status: ${response.statusCode}');
      }

      final data = _asMap(response.data);
      final success = data['status'] == 'success' || data['success'] == true;

      if (!success) {
        return {
          'success': false,
          'message': _messageFrom(
            data,
            fallback: _text(
              'Failed to fetch requests.',
              'تعذر تحميل طلبات السحب.',
            ),
          ),
          'requests': const <WithdrawalRequest>[],
          'code': data['code']?.toString(),
        };
      }

      final rawRequests = data['requests'];
      final requests = rawRequests is List
          ? rawRequests
              .whereType<Map>()
              .map((item) =>
                  WithdrawalRequest.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <WithdrawalRequest>[];

      return {
        'success': true,
        'message': _messageFrom(
          data,
          fallback: _text(
            'Requests fetched successfully.',
            'تم تحميل الطلبات بنجاح.',
          ),
        ),
        'requests': requests,
        'code': data['code']?.toString(),
      };
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('Wallet requests Dio status: ${error.response?.statusCode}');
      }

      final data = _asMap(error.response?.data);
      return {
        'success': false,
        'message': _messageFrom(
          data,
          fallback: _text(
            'Unable to load wallet data. Please try again.',
            'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
          ),
        ),
        'requests': const <WithdrawalRequest>[],
        'code': data['code']?.toString(),
      };
    } catch (_) {
      return {
        'success': false,
        'message': _text(
          'Unable to load wallet data. Please try again.',
          'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
        ),
        'requests': const <WithdrawalRequest>[],
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asAmountString(dynamic value) {
  if (value is num) {
    return value.toStringAsFixed(2);
  }

  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    return '0.00';
  }

  final parsed = double.tryParse(text);
  return parsed == null ? text : parsed.toStringAsFixed(2);
}
