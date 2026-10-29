import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ClientMessageService {
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>> sendClientMessage({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String message,
  }) async {
    try {
      final apiKey = await AuthService.getApiKey();
      final clientId = await AuthService.getUserId();

      if (apiKey == null ||
          apiKey.isEmpty ||
          clientId == null ||
          clientId.isEmpty) {
        return {
          'success': false,
          'message': _text(
            'بيانات الجلسة غير متوفرة. يرجى تسجيل الدخول مرة أخرى.',
            'Session credentials are missing. Please login again.',
          ),
        };
      }

      if (kDebugMode) {
        debugPrint('Sending client support message');
      }

      final response = await _dio.post(
        '${AppUrls.baseUrl}/api_client_messages.php',
        queryParameters: {'lang': AppLocalizations.isRTL ? 'ar' : 'en'},
        data: FormData.fromMap({
          'client_id': clientId,
          'firstname': firstname,
          'lastname': lastname,
          'phone': phone,
          'email': email,
          'message': message,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('Support message response status: ${response.statusCode}');
      }

      final data = _asMap(response.data);
      final success = _isSuccessResponse(response.statusCode, data);

      return {
        'success': success,
        'data': data,
        'message': _readMessage(
          data,
          fallback: success
              ? _text('تم إرسال الرسالة بنجاح', 'Message sent successfully')
              : _text('تعذر إرسال الرسالة. حاول مرة أخرى',
                  'Unable to send message. Please try again'),
        ),
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return {
        'success': false,
        'data': data,
        'message': _readMessage(
          data,
          fallback: _text('تعذر الاتصال. يرجى المحاولة مرة أخرى.',
              'Unable to connect. Please try again.'),
        ),
      };
    } catch (_) {
      return {
        'success': false,
        'message': _text('حدث خطأ غير متوقع. حاول مرة أخرى.',
            'Unexpected error. Please try again.'),
      };
    }
  }

  static bool _isSuccessResponse(int? statusCode, Map<String, dynamic> data) {
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      return false;
    }

    final success = data['success'];
    if (success == true || success?.toString().toLowerCase() == 'true') {
      return true;
    }

    final status = data['status']?.toString().toLowerCase();
    final code = data['code']?.toString().toUpperCase();
    return status == 'success' || code == 'SAVE_SUCCESS';
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static String _readMessage(Map<String, dynamic> data,
      {required String fallback}) {
    final preferredKey = AppLocalizations.isRTL ? 'message_ar' : 'message_en';
    final fallbackKey = AppLocalizations.isRTL ? 'message_en' : 'message_ar';

    for (final key in [preferredKey, 'message', fallbackKey]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  static String _text(String ar, String en) => AppLocalizations.isRTL ? ar : en;
}
