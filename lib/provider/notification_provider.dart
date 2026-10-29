import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseNotificationProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _notifications.clear();
    _fcmToken = null;
    _isLoading = false;
  }

  String? _fcmToken;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  String? get fcmToken => _fcmToken;

  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> initialize() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoading) return;

      _isLoading = true;
      notifyListeners();

      try {
        await guardSession(FirebaseService.initialize(), sessionGeneration);
        _fcmToken = await guardSession(
            FirebaseService.getStoredFCMToken(), sessionGeneration);
        await guardSession(
            FirebaseService.syncClientMessagingSetup(), sessionGeneration);
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (kDebugMode) {
          debugPrint('Error initializing notification provider');
        }
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

  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification['isRead'] = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  int get unreadCount {
    return _notifications
        .where((notification) => notification['isRead'] != true)
        .length;
  }

  Future<void> testTopicSubscriptions() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.syncClientMessagingSetup(), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  Future<void> forceTopicSubscription() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.syncClientMessagingSetup(), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  Future<void> testTopicUnsubscriptions() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.unsubscribeFromClientTopics(), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  Future<void> getSubscriptionStatus() async {
    final sessionGeneration = stateGeneration;
    try {
      if (!kDebugMode) return;

      final userId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final fcmToken = await guardSession(
          FirebaseService.getStoredFCMToken(), sessionGeneration);

      debugPrint('Subscription status summary');
      debugPrint('User ID available: ${userId != null}');
      debugPrint('FCM token available: ${fcmToken != null}');
      debugPrint('Provider loading: $_isLoading');
      debugPrint('Notifications count: ${_notifications.length}');
      debugPrint('Unread count: $unreadCount');
    } on SessionChanged {
      return;
    }
  }

  void updateFCMToken(String? token) {
    _fcmToken = token;
    notifyListeners();
  }

  Future<void> logout() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.unsubscribeFromClientTopics(), sessionGeneration);
      _notifications.clear();
      _fcmToken = null;
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.subscribeToTopic(topic), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(
          FirebaseService.unsubscribeFromTopic(topic), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }
}
