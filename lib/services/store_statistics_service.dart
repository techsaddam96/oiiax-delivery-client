import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/store_statistics.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/client_rating_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'user_session_state.dart';

class StoreStatisticsService {
  @visibleForTesting
  static Dio Function() dioFactory = sessionDio;
  @visibleForTesting
  static Future<double> Function() ratingLoader = _loadRating;
  static Future<double> _loadRating() async =>
      (await ClientRatingService.getClientRating())?.avgRating ?? 0.0;
  @visibleForTesting
  static void resetForTesting() {
    dioFactory = sessionDio;
    ratingLoader = _loadRating;
    clearCache();
  }

  static StoreStatistics? _cachedStatistics;
  static DateTime? _lastFetchTime;
  static int? _cachedGeneration;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<StoreStatistics?> getStoreStatistics({
    bool forceRefresh = false,
  }) async {
    final generation = UserSessionState.generation;
    if (!forceRefresh &&
        _cachedGeneration == generation &&
        _cachedStatistics != null &&
        _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        return _cachedStatistics!;
      }
    }

    try {
      final dio = protectSessionDio(dioFactory());
      final session = await AuthService.getSession();
      if (generation != UserSessionState.generation) return null;
      final apiKey = session.apiKey;
      final clientId = session.clientId;

      if (apiKey == null || clientId == null) {
        if (kDebugMode) {
          debugPrint('Missing API key or client ID');
        }
        return null;
      }

      final response = await dio.post(
        AppUrls.clientStatistics,
        data: {
          'client_id': clientId,
          'api_key': apiKey,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (generation != UserSessionState.generation) return null;
      if (kDebugMode) {
        debugPrint('Store statistics status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] != null) {
            double rating = 0.0;
            try {
              rating = await ratingLoader();
            } catch (_) {
              rating = 0.0;
            }

            if (generation != UserSessionState.generation) return null;
            final statistics =
                StoreStatistics.fromJsonWithRating(data['data'], rating);
            _cachedStatistics = statistics;
            _cachedGeneration = generation;
            _lastFetchTime = DateTime.now();
            return statistics;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching store statistics');
        if (e is DioException) {
          debugPrint('Store statistics Dio status: ${e.response?.statusCode}');
        }
      }
    }

    return null;
  }

  static void clearCache() {
    _cachedStatistics = null;
    _lastFetchTime = null;
    _cachedGeneration = null;
  }

  static StoreStatistics getDefaultStatistics() {
    return StoreStatistics(
      totalOrders: 0,
      activeOrders: 0,
      revenue: '0.00 JOD',
      dueBalance: '0.00 JOD',
      rating: 0.0,
      totalShipments: 0,
      shipmentsInProgress: 0,
      shipmentsDelivered: 0,
      cancelledShipments: 0,
    );
  }
}
