import 'dart:convert';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:http/http.dart' as http;

class DriverRatingSubmissionResult {
  const DriverRatingSubmissionResult({
    required this.success,
    required this.message,
    required this.code,
    this.driverId,
    this.shipmentId,
    this.rating,
  });

  final bool success;
  final String message;
  final String code;
  final int? driverId;
  final int? shipmentId;
  final int? rating;
}

class DriverRatingService {
  static Future<DriverRatingSubmissionResult> submitDriverRating({
    required int shipmentId,
    required int rating,
    String comment = '',
  }) async {
    final apiKey = await AuthService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return DriverRatingSubmissionResult(
        success: false,
        message: AppTranslations.getText('driver_rating_session_expired'),
        code: 'API_KEY_MISSING',
      );
    }

    final languageCode = AppLocalizations.currentLocale.languageCode;

    try {
      final requestData = {
        'shipment_id': shipmentId.toString(),
        'rating': rating.toString(),
        'comment': comment.trim(),
      };
      final lease = RequestIdService.acquire(
        operation: 'client.submitDriverRating',
        payload: requestData,
      );
      final response = await http
          .post(
            Uri.parse(AppUrls.addDriverReview),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'X-API-KEY': apiKey,
              'Accept-Language': languageCode,
              ...lease.headers(),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 20));
      lease.complete();

      final body = _tryDecode(response.body);
      final success = body['success'] == true ||
          (body['status']?.toString().toLowerCase() == 'success');
      final message = _pickMessage(
        body,
        success: success,
        requestLanguage: languageCode,
      );
      final code = body['code']?.toString() ?? '';

      return DriverRatingSubmissionResult(
        success: success,
        message: message,
        code: code,
        driverId: _parseNullableInt(body['driver_id']),
        shipmentId: _parseNullableInt(body['shipment_id']),
        rating: _parseNullableInt(body['rating']) ?? rating,
      );
    } catch (_) {
      return DriverRatingSubmissionResult(
        success: false,
        message: AppTranslations.getText('driver_rating_failed'),
        code: 'REQUEST_FAILED',
      );
    }
  }

  static Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  static String _pickMessage(
    Map<String, dynamic> body, {
    required bool success,
    required String requestLanguage,
  }) {
    final language = AppLocalizations.currentLocale.languageCode;
    final fallback = AppTranslations.getText(
      success ? 'driver_rating_success' : 'driver_rating_failed',
    );
    // Prefer the app's language, even when the device or generic reply differs.
    final candidates = [
      body['message_$language'],
      if (success) fallback,
      if (requestLanguage == language) ...[body['message'], body['error']],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return int.tryParse(value.toString());
}
