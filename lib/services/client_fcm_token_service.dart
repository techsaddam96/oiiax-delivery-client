import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ClientFcmTokenService {
  static final Dio _dio = sessionDio();

  static Future<bool> updateClientFcmToken({
    required String clientId,
    required String apiKey,
    required String fcmToken,
  }) async {
    final normalizedClientId = clientId.trim();
    final normalizedToken = fcmToken.trim();

    if (normalizedClientId.isEmpty || apiKey.trim().isEmpty) {
      return false;
    }

    if (normalizedToken.length < 20) {
      if (kDebugMode) {
        debugPrint('FCM token registration skipped: invalid token length');
      }
      return false;
    }

    try {
      final response = await _dio.post(
        AppUrls.updateClientFcmToken,
        data: {
          'client_id': normalizedClientId,
          'fcm_token': normalizedToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data;
      final updated = response.statusCode == 200 &&
          data is Map &&
          (data['success'] == true || data['status'] == 'success');

      if (kDebugMode) {
        debugPrint(updated
            ? 'FCM token registration succeeded'
            : 'FCM token registration failed');
      }

      return updated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token registration failed');
      }
      return false;
    }
  }
}
