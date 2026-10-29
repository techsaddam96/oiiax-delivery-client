import 'dart:async';
import 'dart:convert';
import 'user_session_state.dart';
import 'shipment_sync.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:blockatie/firebase_options.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/client_fcm_token_service.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/chat/conversation_page.dart';
import 'package:blockatie/views/pages/statements/client_statement_details_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static const AndroidNotificationChannel _generalNotificationChannel =
      AndroidNotificationChannel(
    'blockatie_alerts_v2',
    'OIIAX Notifications',
    description: 'Shipment, wallet, and account alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  static const AndroidNotificationChannel _chatNotificationChannel =
      AndroidNotificationChannel(
    'blockatie_chat_alerts_v2',
    'OIIAX Chat',
    description: 'Chat message alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static bool _coreInitialized = false;
  static bool _isInitialized = false;
  static bool _tokenRefreshListenerAttached = false;
  static bool _messageHandlersAttached = false;
  static bool _localNotificationsInitialized = false;
  static bool _notificationPermissionRequested = false;
  static final Set<String> _subscribedTopics = {};
  static final Set<String> _handledNavigationTargets = {};
  static Map<String, dynamic>? _pendingInitialNavigation;
  static bool _authenticatedShellReady = false;

  static String? get fcmToken => _fcmToken;
  static Future<void> _messagingQueue = Future<void>.value();
  static bool _isolationConfigured = false;

  static void configureSessionIsolation() {
    if (_isolationConfigured) return;
    _isolationConfigured = true;
    UserSessionState.register(_resetMessaging);
  }

  static Future<void> _serializeMessaging(Future<void> Function() action) {
    final operation = _messagingQueue.then((_) => action());
    _messagingQueue = operation.catchError((_) {});
    return operation;
  }

  static void _resetMessaging() {
    _handledNavigationTargets.clear();
    _pendingInitialNavigation = null;
    _authenticatedShellReady = false;
    unawaited(_serializeMessaging(() async {
      if (!_coreInitialized) return;
      for (final topic in List<String>.of(_subscribedTopics)) {
        await unsubscribeFromTopic(topic);
      }
      // Rotate only the messaging credential, not Firebase or global listeners.
      // An old account's direct pushes must not remain deliverable on this device.
      await deleteFCMToken();
      if (_localNotificationsInitialized) await _localNotifications.cancelAll();
      if (await AppBadgePlus.isSupported()) await AppBadgePlus.updateBadge(0);
    }).catchError((_) {}));
  }

  @visibleForTesting
  static bool canDisplayAccountPayload(Map<String, dynamic> data) {
    final recipient =
        data['client_id'] ?? data['recipient_id'] ?? data['user_id'];
    final role = data['recipient_role'] ?? data['user_role'];
    return recipient != null &&
        (role == null || role == 'client') &&
        _belongsToSession(data);
  }

  static bool _belongsToSession(Map<String, dynamic> data) {
    final session = AuthService.currentSession;
    if (session?.isValid != true) return false;
    final recipient =
        data['client_id'] ?? data['recipient_id'] ?? data['user_id'];
    return recipient == null || recipient.toString() == session!.clientId;
  }

  static final Map<String, List<Function(Map<String, dynamic>)>>
      _servicesSubscribers = {};
  static final List<void Function(Map<String, dynamic>)>
      _allNotificationSubscribers = [];

  static Future<void> initialize() async {
    configureSessionIsolation();
    if (_isInitialized) return;

    try {
      await _ensureCoreInitialized();
      await _requestNotificationPermission();
      await _initializeLocalNotifications();
      _setupMessageHandlers();
      await _getFCMToken();
      _setupTokenRefreshHandler();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('Firebase initialized');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed');
      }
    }
  }

  static Future<void> _ensureCoreInitialized() async {
    if (_coreInitialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _coreInitialized = true;
  }

  static Future<void> _requestNotificationPermission() async {
    if (_notificationPermissionRequested) return;

    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _notificationPermissionRequested = true;
      if (kDebugMode) {
        debugPrint(
          'Notification permission status: ${settings.authorizationStatus}',
        );
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Notification permission request failed');
      }
    }
  }

  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null && _fcmToken!.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      if (kDebugMode) {
        debugPrint(
          _fcmToken == null ? 'FCM token unavailable' : 'FCM token ready',
        );
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('FCM token retrieval failed');
      }
    }
  }

  static void _setupTokenRefreshHandler() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;

    _firebaseMessaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      await syncClientMessagingSetup();
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications
        ?.createNotificationChannel(_generalNotificationChannel);
    await androidNotifications
        ?.createNotificationChannel(_chatNotificationChannel);

    _localNotificationsInitialized = true;
  }

  static void _setupMessageHandlers() {
    if (_messageHandlersAttached) return;
    _messageHandlersAttached = true;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!_belongsToSession(message.data)) return;
    if (!_handleNotifications(message)) return;
    if (kDebugMode) {
      debugPrint('Foreground notification received');
    }

    final isChatMessage = message.data['type']?.toString() == 'chat';
    if (message.notification != null || isChatMessage) {
      await _showLocalNotification(message);
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (!_belongsToSession(message.data)) return;
    final generation = UserSessionState.generation;
    if (kDebugMode) {
      debugPrint('Background notification opened');
    }

    if (await AppBadgePlus.isSupported()) {
      if (generation == UserSessionState.generation) {
        AppBadgePlus.updateBadge(1);
      }
    }

    _handleNotifications(message);
    unawaited(_handleMessageNavigation(message.data));
  }

  static Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message == null) return;
    final epoch = UserSessionState.generation;
    await AuthService.getSession();
    if (epoch != UserSessionState.generation ||
        !canDisplayAccountPayload(message.data)) {
      return;
    }

    if (kDebugMode) {
      debugPrint('Initial notification opened');
    }
    _handleNotifications(message);
    _pendingInitialNavigation = Map<String, dynamic>.of(message.data);
    if (_authenticatedShellReady) authenticatedShellReady();
  }

  static void authenticatedShellReady() {
    _authenticatedShellReady = true;
    final data = _pendingInitialNavigation;
    _pendingInitialNavigation = null;
    if (data != null) unawaited(_handleMessageNavigation(data));
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_belongsToSession(message.data)) return;
    final trustedPayload = canDisplayAccountPayload(message.data);
    final isChatMessage = message.data['type']?.toString() == 'chat';
    final channel =
        isChatMessage ? _chatNotificationChannel : _generalNotificationChannel;
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      (trustedPayload ? message.notification?.title : null) ??
          (isChatMessage
              ? AppTranslations.getText('conversations')
              : 'New Notification'),
      (trustedPayload ? message.notification?.body : null) ??
          (isChatMessage ? AppTranslations.getText('chat_new_messages') : ''),
      platformDetails,
      payload:
          json.encode(trustedPayload ? message.data : {'type': 'notification'}),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = json.decode(response.payload!);
      if (data is Map<String, dynamic>) {
        unawaited(_handleMessageNavigation(data));
      }
    } on FormatException {/* Ignore malformed local notification payloads. */}
  }

  static Future<void> _handleMessageNavigation(
      Map<String, dynamic> data) async {
    final generation = UserSessionState.generation;
    if (!canDisplayAccountPayload(data)) return;
    final notificationType = data['type']?.toString().trim();
    final session = await AuthService.getSession();
    if (!session.isValid ||
        generation != UserSessionState.generation ||
        !_belongsToSession(data)) {
      return;
    }

    if (notificationType == 'client_statement') {
      final statementId = _positiveInt(data['statement_id'] ?? data['item_id']);
      if (statementId != null) {
        _navigateOnce(
          'client_statement:${session.clientId}:$statementId',
          ClientStatementDetailsPage(statementId: statementId),
          navIndex: 4,
        );
      }
      return;
    }

    if (notificationType == 'chat' || notificationType == 'chat_message') {
      final conversationId = _positiveInt(data['conversation_id']);
      if (conversationId == null) {
        if (kDebugMode) {
          debugPrint('Chat notification is missing a conversation target');
        }
        return;
      }
      final shipmentId = _positiveInt(data['shipment_id'] ?? data['item_id']);
      _navigateOnce(
        'chat:${session.clientId}:$conversationId',
        ConversationPage(
          conversationId: conversationId,
          title: AppTranslations.getText('conversations'),
          shipmentId: shipmentId,
        ),
        navIndex: 4,
      );
      return;
    }

    final shipmentId = ShipmentSync.target(data);
    if (shipmentId != null) {
      _navigateOnce(
        'shipment:${session.clientId}:${data['event_id'] ?? shipmentId}',
        OrderDetailPage(orderId: shipmentId),
        navIndex: 1,
      );
      return;
    }
    if (!kDebugMode) return;
    switch (notificationType) {
      case 'shipment_update':
        debugPrint('Navigate to shipment notification target');
        break;
      case 'new_shipment':
        debugPrint('Navigate to new shipment notification');
        break;
      case 'payment':
        debugPrint('Navigate to payment notification');
        break;
      default:
        debugPrint('Default notification navigation');
        break;
    }
  }

  static void _navigateOnce(String target, Widget page,
      {required int navIndex}) {
    final generation = UserSessionState.generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != UserSessionState.generation ||
          Nav.key.currentState == null ||
          !_handledNavigationTargets.add(target)) {
        return;
      }
      Nav.to(page, withNav: true, navIndex: navIndex);
      if (target.startsWith('shipment:')) {
        // Deduplicate duplicate callbacks, not a later deliberate tap on the same alert.
        Timer(const Duration(seconds: 2), () {
          if (generation == UserSessionState.generation) {
            _handledNavigationTargets.remove(target);
          }
        });
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  static int? _positiveInt(Object? value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static Future<bool> subscribeToTopic(String topic) async {
    if (_subscribedTopics.contains(topic)) {
      return true;
    }

    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _subscribedTopics.add(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe to topic');
      }
      return false;
    }
  }

  static Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _subscribedTopics.remove(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to unsubscribe from topic');
      }
      return false;
    }
  }

  static List<String> _clientTopics(String clientId) => [
        'owner_$clientId',
        'allowners',
        'announcements',
        'shipment_updates',
        'payment_notifications',
        'client_all',
        'client_notifications',
        'maintenance',
      ];

  static Future<void> syncClientMessagingSetup({
    String? clientId,
    String? apiKey,
  }) {
    configureSessionIsolation();
    final generation = UserSessionState.generation;
    return _serializeMessaging(() async {
      final session = await AuthService.getSession();
      bool current() =>
          generation == UserSessionState.generation &&
          session.isValid &&
          AuthService.currentSession?.apiKey == session.apiKey;
      if (!current() ||
          (clientId != null && clientId != session.clientId) ||
          (apiKey != null && apiKey != session.apiKey)) {
        return;
      }
      await initialize();
      if (!current()) return;
      if (_fcmToken == null || _fcmToken!.isEmpty) await _getFCMToken();
      if (!current()) return;
      final token = _fcmToken;
      if (token != null && token.isNotEmpty) {
        await ClientFcmTokenService.updateClientFcmToken(
            clientId: session.clientId!,
            apiKey: session.apiKey!,
            fcmToken: token);
      }
      for (final topic in _clientTopics(session.clientId!)) {
        if (!current()) return;
        await subscribeToTopic(topic);
      }
    });
  }

  static Future<void> unsubscribeFromClientTopics({String? clientId}) {
    return _serializeMessaging(() async {
      final id = clientId ?? (await AuthService.getSession()).clientId;
      if (id == null || id.isEmpty) return;
      for (final topic in _clientTopics(id)) {
        await unsubscribeFromTopic(topic);
      }
    });
  }

  static Future<String?> getStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      _fcmToken = null;
      if (kDebugMode) {
        debugPrint('FCM token deleted');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('FCM token deletion failed');
      }
    }
  }

  static Future<void> debugTopicSubscription() async {
    try {
      final success = await subscribeToTopic('announcements');
      final token = await getStoredFCMToken();

      if (kDebugMode) {
        debugPrint(
          'Topic subscription test: ${success ? "SUCCESS" : "FAILED"}',
        );
        debugPrint(
          token == null ? 'FCM token unavailable' : 'FCM token stored',
        );
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Debug topic subscription failed');
      }
    }
  }

  static bool _handleNotifications(RemoteMessage message) {
    if (!_belongsToSession(message.data)) return false;
    if ((message.data['type'] == 'shipment_status_updated' ||
            ShipmentSync.target(message.data) != null) &&
        !ShipmentSync.dispatch(message.data)) {
      return false;
    }
    final data = canDisplayAccountPayload(message.data)
        ? message.data
        : <String, dynamic>{'type': message.data['type']};
    final service = message.data['type'] ?? '';

    if (_servicesSubscribers.isNotEmpty &&
        _servicesSubscribers[service] != null) {
      for (final element in _servicesSubscribers[service]!) {
        element(data);
      }
    }

    for (final callback in List<void Function(Map<String, dynamic>)>.from(
      _allNotificationSubscribers,
    )) {
      callback(data);
    }
    return true;
  }

  /// Registers one app-level listener for every foreground notification.
  /// The callback receives only the notification data needed for refreshing UI.
  static void subscribeToAllNotifications(
    void Function(Map<String, dynamic>) callback,
  ) {
    if (!_allNotificationSubscribers.contains(callback)) {
      _allNotificationSubscribers.add(callback);
    }
  }

  static void unsubscribeFromAllNotifications(
    void Function(Map<String, dynamic>) callback,
  ) {
    _allNotificationSubscribers.remove(callback);
  }

  static void subscribeToServiceNotifications({
    required Function(Map<String, dynamic>) callBack,
    required NotificationsServiceEnum service,
  }) {
    final serviceId = service.type;

    if (_servicesSubscribers.containsKey(serviceId)) {
      _servicesSubscribers[serviceId]!.add(callBack);
    } else {
      _servicesSubscribers[serviceId] = [callBack];
    }
  }

  static void unsubscribeToServiceNotifications({
    required NotificationsServiceEnum service,
    Function(Map<String, dynamic>)? callBack,
  }) {
    final subscribers = _servicesSubscribers[service.type];
    if (subscribers == null) {
      return;
    }
    if (callBack == null) {
      _servicesSubscribers.remove(service.type);
      return;
    }
    subscribers.remove(callBack);
    if (subscribers.isEmpty) {
      _servicesSubscribers.remove(service.type);
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    debugPrint('Handling a background message');
  }
}

enum NotificationsServiceEnum {
  chat(type: 'chat'),
  shipmentAssigned(type: 'shipment_assigned'),
  shipmentUpdate(type: 'shipment_update');

  final String type;
  const NotificationsServiceEnum({required this.type});
}
