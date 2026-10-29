import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/blockatie_pro_package.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BlockatieProService {
  static Future<BlockatieProResponse?> getPackages() async {
    try {
      final dio = Dio();
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        if (kDebugMode) {
          debugPrint('Missing client credentials for Blockatie Pro packages');
        }
        return null;
      }

      final response = await dio.post(
        AppUrls.blockatieProPackages,
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
        debugPrint('Blockatie Pro packages status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is Map<String, dynamic>) {
          return BlockatieProResponse.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Blockatie Pro Dio status: ${e.response?.statusCode}');
      }
      return null;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Error fetching Blockatie Pro packages');
      }
      return null;
    }
  }
}
