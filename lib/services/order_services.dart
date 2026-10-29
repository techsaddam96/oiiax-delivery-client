import 'dart:convert';
import 'user_session_state.dart';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OrderServices {
  static Future<OrderDetailsResponse?> getOrderDetails({
    required int orderId,
  }) async {
    final generation = UserSessionState.generation;
    try {
      final apiKey = await AuthService.getApiKey();
      if (generation != UserSessionState.generation) return null;
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final response = await http.post(
        Uri.parse(AppUrls.getOrderDetails),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-API-KEY': apiKey,
        },
        body: {
          'order_id': orderId.toString(),
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (kDebugMode) {
        debugPrint('Order details status: ${response.statusCode}');
      }

      if (response.statusCode == 401) {
        await AuthService.invalidateIfCurrent(apiKey, generation);
      }
      if (generation != UserSessionState.generation) return null;
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return OrderDetailsResponse.fromJson(jsonResponse);
      }

      throw Exception('Failed to load order details: ${response.statusCode}');
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Error fetching order details');
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetailsRaw({
    required int orderId,
  }) async {
    final generation = UserSessionState.generation;
    try {
      final apiKey = await AuthService.getApiKey();
      if (generation != UserSessionState.generation) return null;
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final response = await http.post(
        Uri.parse(AppUrls.getOrderDetails),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-API-KEY': apiKey,
        },
        body: {
          'order_id': orderId.toString(),
        },
      );

      if (response.statusCode == 401) {
        await AuthService.invalidateIfCurrent(apiKey, generation);
      }
      if (generation != UserSessionState.generation) return null;
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Failed to load order details: ${response.statusCode}');
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Error fetching raw order details');
      }
      return null;
    }
  }
}
