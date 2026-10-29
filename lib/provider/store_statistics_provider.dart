import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/models/store_statistics.dart';
import 'package:blockatie/services/store_statistics_service.dart';

class StoreStatisticsProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _statistics = null;
    _isLoading = false;
    _error = null;
  }

  StoreStatistics? _statistics;
  bool _isLoading = false;
  String? _error;

  StoreStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch store statistics from API
  Future<void> fetchStoreStatistics({bool forceRefresh = false}) async {
    final sessionGeneration = stateGeneration;
    try {
      // Prevent multiple simultaneous requests
      if (_isLoading) {
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final statistics = await guardSession(
            StoreStatisticsService.getStoreStatistics(
              forceRefresh: forceRefresh,
            ),
            sessionGeneration);

        if (statistics != null) {
          _statistics = statistics;
          _error = null;
        } else {
          // Use default statistics if API fails
          _statistics = StoreStatisticsService.getDefaultStatistics();
          _error = 'Failed to load store statistics. Using default values.';
        }
      } catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _error =
            'Network error: Unable to connect to server. Please try again.';
        _statistics = StoreStatisticsService.getDefaultStatistics();
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear cached data
  void clearCache() {
    StoreStatisticsService.clearCache();
    _statistics = null;
    _error = null;
    notifyListeners();
  }

  /// Get formatted statistics for display
  String getFormattedTotalOrders() {
    return _statistics?.totalOrders.toString() ?? '0';
  }

  String getFormattedActiveOrders() {
    return _statistics?.activeOrders.toString() ?? '0';
  }

  String getFormattedRevenue() {
    return _statistics?.revenue ?? '0.00 JOD';
  }

  String getFormattedRating() {
    final rating = _statistics?.rating ?? 0.0;
    return '${rating.toStringAsFixed(1)} ★';
  }

  /// Get the raw rating value for other uses
  double getRating() {
    return _statistics?.rating ?? 0.0;
  }

  /// Check if rating is available
  bool get hasRating => _statistics?.rating != null && _statistics!.rating > 0;
}
