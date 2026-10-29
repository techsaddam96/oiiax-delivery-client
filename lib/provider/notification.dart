import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/session_refresh_queue.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/notifications.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends UserScopedNotifier {
  NotificationProvider({Dio? dio}) {
    if (dio != null) _dio = protectSessionDio(dio);
  }
  @override
  void clearUserState() {
    notificationData = null;
    unreadCount = 0;
    isLoading = false;
    isRefreshing = false;
    isLoadingMore = false;
    _isFetching = false;
    errorKey = null;
    _currentPage = 1;
    _hasMore = false;
    _readingIds.clear();
    _updateAppBadge(0);
  }

  Dio _dio = sessionDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static const int _defaultLimit = 20;

  NotificationResponse? notificationData;
  bool isLoading = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  String? errorKey;
  int unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isFetching = false;
  final Set<int> _readingIds = <int>{};

  List<NotificationItem> get notifications =>
      notificationData?.notifications ?? const <NotificationItem>[];

  bool get hasMore => _hasMore;

  bool get supportsMarkAllRead => false;

  bool isReading(int recipientRowId) => _readingIds.contains(recipientRowId);

  Future<void> fetchClientNotifications({
    bool force = false,
    bool refresh = false,
    int limit = _defaultLimit,
  }) {
    if (!force && !refresh && notifications.isNotEmpty) return Future.value();
    return _refreshQueue.run(
      () => _fetchNotifications(force: true, refresh: refresh, limit: limit),
      trailing: force || refresh,
    );
  }

  late final _refreshQueue = SessionRefreshQueue(() => stateGeneration);
  Future<void> _fetchNotifications({
    bool force = false,
    bool refresh = false,
    int limit = _defaultLimit,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isFetching) {
        return;
      }
      if (!force &&
          !refresh &&
          notificationData != null &&
          notifications.isNotEmpty) {
        return;
      }

      _isFetching = true;
      errorKey = null;

      if (refresh) {
        isRefreshing = true;
      } else if (notifications.isEmpty) {
        isLoading = true;
      }
      notifyListeners();

      try {
        final session =
            await guardSession(AuthService.getSession(), sessionGeneration);
        if (!session.isValid) {
          _setError('notifications_unauthorized_error');
          return;
        }

        final response = await guardSession(
            _dio.post(
              AppUrls.getNotificatios,
              options: _requestOptions(session.apiKey!),
              data: {
                'client_id': session.clientId,
                'page': 1,
                'limit': limit,
              },
            ),
            sessionGeneration);

        final data = _normalizeMap(response.data);
        if (_isSuccessResponse(response.statusCode, data)) {
          final parsed = NotificationResponse.fromJson(data);
          notificationData = parsed;
          unreadCount = parsed.unreadCount;
          _currentPage = parsed.page <= 0 ? 1 : parsed.page;
          _hasMore = _resolveHasMore(parsed);
          errorKey = null;
          await guardSession(_updateAppBadge(unreadCount), sessionGeneration);
          return;
        }

        _setError(_mapResponseToErrorKey(response.statusCode, data));
        _logFailure('Notifications fetch', response.statusCode, data);
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _setError(_mapDioToErrorKey(error));
        _logDioFailure('Notifications fetch', error);
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _setError('notifications_generic_error');
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoading = false;
          isRefreshing = false;
          _isFetching = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> loadMoreNotifications({int limit = _defaultLimit}) =>
      _refreshQueue.run(() => _loadMoreNotifications(limit: limit),
          trailing: false);

  Future<void> _loadMoreNotifications({int limit = _defaultLimit}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isFetching || isLoadingMore || !_hasMore || notifications.isEmpty) {
        return;
      }

      final session =
          await guardSession(AuthService.getSession(), sessionGeneration);
      if (!session.isValid) {
        return;
      }

      _isFetching = true;
      isLoadingMore = true;
      notifyListeners();

      try {
        final nextPage = _currentPage + 1;
        final response = await guardSession(
            _dio.post(
              AppUrls.getNotificatios,
              options: _requestOptions(session.apiKey!),
              data: {
                'client_id': session.clientId,
                'page': nextPage,
                'limit': limit,
              },
            ),
            sessionGeneration);

        final data = _normalizeMap(response.data);
        if (_isSuccessResponse(response.statusCode, data)) {
          final parsed = NotificationResponse.fromJson(data);
          final merged = _mergeNotifications(
            current: notifications,
            incoming: parsed.notifications,
          );

          notificationData = parsed.copyWith(notifications: merged);
          unreadCount = parsed.unreadCount;
          _currentPage = nextPage;
          _hasMore = _resolveHasMore(parsed);
          errorKey = null;
          await guardSession(_updateAppBadge(unreadCount), sessionGeneration);
        } else {
          _logFailure('Notifications load-more', response.statusCode, data);
        }
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _logDioFailure('Notifications load-more', error);
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        // Keeping the current list is safer than replacing it with an error state.
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoadingMore = false;
          _isFetching = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<bool> readNotification({required int recipientRowId}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (recipientRowId <= 0) {
        return false;
      }
      if (_readingIds.contains(recipientRowId)) {
        return false;
      }

      final currentItem = _findByRecipientRowId(recipientRowId);
      if (currentItem != null && !currentItem.isUnread) {
        return true;
      }

      final session =
          await guardSession(AuthService.getSession(), sessionGeneration);
      if (!session.isValid) {
        return false;
      }

      _readingIds.add(recipientRowId);
      notifyListeners();

      try {
        final response = await guardSession(
            _dio.post(
              AppUrls.readNotification,
              options: _requestOptions(session.apiKey!),
              data: {'id': recipientRowId},
            ),
            sessionGeneration);

        final data = _normalizeMap(response.data);
        if (_isSuccessResponse(response.statusCode, data)) {
          _markReadLocally(recipientRowId);
          await guardSession(_updateAppBadge(unreadCount), sessionGeneration);
          return true;
        }

        _logFailure('Notification read', response.statusCode, data);
        return false;
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _logDioFailure('Notification read', error);
        return false;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _readingIds.remove(recipientRowId);
          notifyListeners();
        }
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<void> clearState() async {
    final sessionGeneration = stateGeneration;
    try {
      notificationData = null;
      isLoading = false;
      isRefreshing = false;
      isLoadingMore = false;
      errorKey = null;
      unreadCount = 0;
      _currentPage = 1;
      _hasMore = false;
      _isFetching = false;
      _readingIds.clear();
      await guardSession(_updateAppBadge(0), sessionGeneration);
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  void _setError(String key) {
    errorKey = key;
  }

  Options _requestOptions(String apiKey) {
    return Options(
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-API-KEY': apiKey,
      },
    );
  }

  NotificationItem? _findByRecipientRowId(int recipientRowId) {
    for (final notification in notifications) {
      if (notification.recipientRowId == recipientRowId) {
        return notification;
      }
    }
    return null;
  }

  void _markReadLocally(int recipientRowId) {
    final data = notificationData;
    if (data == null) {
      return;
    }

    var didChange = false;
    final updatedNotifications = data.notifications.map((notification) {
      if (notification.recipientRowId != recipientRowId ||
          !notification.isUnread) {
        return notification;
      }
      didChange = true;
      return notification.copyWith(
        isRead: 1,
        readAt: DateTime.now().toIso8601String(),
      );
    }).toList(growable: false);

    if (!didChange) {
      return;
    }

    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    notificationData = data.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  List<NotificationItem> _mergeNotifications({
    required List<NotificationItem> current,
    required List<NotificationItem> incoming,
  }) {
    final merged = <NotificationItem>[...current];
    final existingIds = current
        .map((item) => item.recipientRowId > 0 ? item.recipientRowId : item.id)
        .toSet();

    for (final item in incoming) {
      final uniqueId = item.recipientRowId > 0 ? item.recipientRowId : item.id;
      if (existingIds.add(uniqueId)) {
        merged.add(item);
      }
    }
    return merged;
  }

  bool _resolveHasMore(NotificationResponse response) {
    return response.hasMore;
  }

  bool _isSuccessResponse(int? statusCode, Map<String, dynamic> data) {
    return statusCode == 200 && data['status']?.toString() == 'success';
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  String _mapResponseToErrorKey(int? statusCode, Map<String, dynamic> data) {
    if (statusCode == 401 || statusCode == 403) {
      return 'notifications_unauthorized_error';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'notifications_server_error';
    }

    final code = (data['code'] ?? data['status'])?.toString().toUpperCase();
    if (code == 'INVALID_API_KEY' || code == 'FORBIDDEN_CLIENT') {
      return 'notifications_unauthorized_error';
    }
    return 'notifications_generic_error';
  }

  String _mapDioToErrorKey(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'notifications_timeout_error';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'notifications_network_error';
      case DioExceptionType.badResponse:
        return _mapResponseToErrorKey(
          error.response?.statusCode,
          _normalizeMap(error.response?.data),
        );
      case DioExceptionType.cancel:
        return 'notifications_generic_error';
      case DioExceptionType.badCertificate:
        return 'notifications_server_error';
    }
  }

  Future<void> _updateAppBadge(int count) async {
    final sessionGeneration = stateGeneration;
    try {
      if (await guardSession(AppBadgePlus.isSupported(), sessionGeneration)) {
        await guardSession(AppBadgePlus.updateBadge(count), sessionGeneration);
      }
    } on SessionChanged {
      return;
    }
  }

  void _logFailure(String scope, int? statusCode, Map<String, dynamic> data) {
    if (!kDebugMode) {
      return;
    }

    final code = (data['code'] ?? data['status'] ?? 'UNKNOWN').toString();
    debugPrint('$scope failed: status=$statusCode code=$code');
  }

  void _logDioFailure(String scope, DioException error) {
    if (!kDebugMode) {
      return;
    }

    final data = _normalizeMap(error.response?.data);
    final code = (data['code'] ?? data['status'] ?? 'UNKNOWN').toString();
    debugPrint(
      '$scope failed: type=${error.type.name} '
      'status=${error.response?.statusCode} code=$code',
    );
  }
}
