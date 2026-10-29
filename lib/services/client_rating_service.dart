import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/client_rating.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ClientRatingService {
  static Future<ClientRating?> getClientRating() async {
    try {
      final dio = sessionDio();
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        if (kDebugMode) {
          debugPrint('Missing client credentials for rating');
        }
        return null;
      }

      final response = await dio.post(
        AppUrls.clientRating,
        data: {
          'client_id': clientId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (kDebugMode) {
        debugPrint('Client rating status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null &&
            data is Map<String, dynamic> &&
            data['status'] == 'success') {
          return ClientRating.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Client rating Dio status: ${e.response?.statusCode}');
      }
      return null;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Error fetching client rating');
      }
      return null;
    }
  }
}
