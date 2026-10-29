import 'dart:async';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/shipment_sync.dart';
import 'package:blockatie/services/shipment_refresh_coordinator.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';

import 'package:blockatie/provider/add_shipment_provider.dart';
import 'package:blockatie/provider/balance_history.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/provider/filter.dart';
import 'package:blockatie/provider/header.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/login.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/notification_provider.dart';
import 'package:blockatie/provider/orders.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/provider/store_statistics_provider.dart';
import 'package:blockatie/provider/statements/client_statements_provider.dart';
import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/provider/time.dart';
import 'package:blockatie/provider/wallet.dart';
import 'package:blockatie/provider/withdrawal.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/chat_launcher_navigation_observer.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/theme.dart';
import 'package:blockatie/views/pages/connectivity/connection_alert_screen.dart';
import 'package:blockatie/views/pages/splash/splash.dart';
import 'package:blockatie/views/widgets/floating_chat_bubble.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppUrls.validateActiveConfiguration();
  AppUrls.logActiveEnvironment();

  await AppLocalizations.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ChatLauncherProvider _chatLauncherProvider;
  late final ChatConversationsProvider _chatConversationsProvider;
  late final ChatLauncherNavigationObserver _chatNavigationObserver;
  bool _didLoadChatUnreadForSession = false;

  @override
  void initState() {
    super.initState();
    FirebaseService.configureSessionIsolation();
    UserSessionState.changes.addListener(_onSessionTransition);
    _chatLauncherProvider = ChatLauncherProvider();
    _chatConversationsProvider = ChatConversationsProvider(
      repository: ChatService(),
    );
    _chatNavigationObserver =
        ChatLauncherNavigationObserver(_chatLauncherProvider);
    _chatLauncherProvider.addListener(_onChatLauncherStateChanged);
    unawaited(_initializeChatLauncher());
    FirebaseService.subscribeToServiceNotifications(
      service: NotificationsServiceEnum.chat,
      callBack: _onChatNotification,
    );
  }

  @override
  void dispose() {
    UserSessionState.changes.removeListener(_onSessionTransition);
    _chatLauncherProvider.removeListener(_onChatLauncherStateChanged);
    FirebaseService.unsubscribeToServiceNotifications(
      service: NotificationsServiceEnum.chat,
      callBack: _onChatNotification,
    );
    _chatConversationsProvider.dispose();
    _chatLauncherProvider.dispose();
    super.dispose();
  }

  void _onSessionTransition() {
    final context = Nav.key.currentContext;
    if (context != null) {
      ScaffoldMessenger.maybeOf(context)?.clearMaterialBanners();
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    }
    if (UserSessionState.lastReason != SessionResetReason.invalidSession) {
      return;
    }
    final generation = UserSessionState.generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == UserSessionState.generation) {
        Nav.offAll(const ClientWelcomePage());
      }
    });
  }

  void _onChatNotification(Map<String, dynamic> _) {
    if (!_chatLauncherProvider.isAuthenticated) {
      return;
    }
    unawaited(_chatConversationsProvider.refreshUnreadCount());
  }

  Future<void> _initializeChatLauncher() async {
    await _chatLauncherProvider.syncSession();
    _onChatLauncherStateChanged();
  }

  void _onChatLauncherStateChanged() {
    if (!_chatLauncherProvider.isAuthenticated) {
      _didLoadChatUnreadForSession = false;

      return;
    }
    if (_didLoadChatUnreadForSession) {
      return;
    }
    _didLoadChatUnreadForSession = true;
    unawaited(_chatConversationsProvider.refreshUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppLocalizations.languageNotifier),
        ChangeNotifierProvider(create: (_) => LoginProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => BottomNavProvider(), lazy: true),
        ChangeNotifierProvider.value(value: _chatConversationsProvider),
        ChangeNotifierProvider.value(value: _chatLauncherProvider),
        ChangeNotifierProvider(create: (_) => HomeProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => OrderStatusProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ShipmentProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => FilterProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => TimeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ProfileProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => Headerprovider(), lazy: true),
        ChangeNotifierProvider(create: (_) => WalletProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => FirebaseNotificationProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => ShipmentInstantprovider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => BalanceHistoryProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => AddShipmentProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => SystemSettingsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RequestsProvider(), lazy: true),
        ChangeNotifierProvider(
            create: (_) => StoreStatisticsProvider(), lazy: true),
        ChangeNotifierProvider(
          create: (_) => ClientStatementsProvider(),
          lazy: true,
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) => _ClientDataRefreshScope(
          child: OrientationBuilder(
            builder: (context, orientation) {
              SizeConfig().init(constraints, orientation);
              return OverlaySupport.global(
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  textDirection: TextDirection.ltr,
                  children: [
                    Consumer<LanguageChangeNotifier>(
                      builder: (context, notifier, _) {
                        return MaterialApp(
                          navigatorKey: Nav.key,
                          navigatorObservers: [_chatNavigationObserver],
                          debugShowCheckedModeBanner: false,
                          theme: AppTheme.getPrimaryTheme(),
                          title: AppTranslations.getText('app_name'),
                          supportedLocales: AppLocalizations.supportedLocales,
                          locale: AppLocalizations.currentLocale,
                          localizationsDelegates: const [
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                            AppLocalizationsDelegate(),
                          ],
                          localeResolutionCallback: (locale, supportedLocales) {
                            for (final supportedLocale in supportedLocales) {
                              if (supportedLocale.languageCode ==
                                  locale?.languageCode) {
                                return supportedLocale;
                              }
                            }
                            return supportedLocales.first;
                          },
                          builder: (context, child) {
                            return Theme(
                              data: AppTheme.getPrimaryTheme(),
                              child: Directionality(
                                textDirection: AppLocalizations.textDirection,
                                child: Stack(
                                  children: [
                                    child ?? const SizedBox(),
                                    const FloatingChatBubble(),
                                  ],
                                ),
                              ),
                            );
                          },
                          home: const SplashPage(),
                        );
                      },
                    ),
                    const ConnectionAlert(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Refreshes signed-in client data after a push event or when the app returns
/// to the foreground. It lives above all authenticated pages, so individual
/// screens do not need duplicated Firebase listeners.
class _ClientDataRefreshScope extends StatefulWidget {
  const _ClientDataRefreshScope({required this.child});

  final Widget child;

  @override
  State<_ClientDataRefreshScope> createState() =>
      _ClientDataRefreshScopeState();
}

class _ClientDataRefreshScopeState extends State<_ClientDataRefreshScope>
    with WidgetsBindingObserver {
  late final ShipmentRefreshCoordinator _sync;
  BottomNavProvider? _nav;
  HomeProvider? _home;
  String? _lastSurface;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync = ShipmentRefreshCoordinator(
      refresh: _refreshShipmentSurfaces,
      authenticated: () =>
          mounted && AuthService.currentSession?.isValid == true,
    );
    FirebaseService.subscribeToAllNotifications(_onOtherNotification);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nav != null) return;
    _nav = context.read<BottomNavProvider>()..addListener(_onScreenEntry);
    _home = context.read<HomeProvider>()..addListener(_onScreenEntry);
  }

  void _onScreenEntry() {
    if (!mounted) return;
    final surface =
        '${_nav?.selectedIndex}:${_home?.selectedTabIndex}:${_nav?.overlayPage != null}';
    if (surface == _lastSurface) return;
    _lastSurface = surface;
    if ((_nav?.selectedIndex ?? 4) <= 1 && _nav?.overlayPage == null) {
      _sync.schedule();
    }
  }

  @override
  void dispose() {
    _sync.dispose();
    _nav?.removeListener(_onScreenEntry);
    _home?.removeListener(_onScreenEntry);
    FirebaseService.unsubscribeFromAllNotifications(_onOtherNotification);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sync.foreground = state == AppLifecycleState.resumed;
    if (_sync.foreground) _sync.resumed();
  }

  void _onOtherNotification(Map<String, dynamic> data) {
    if (ShipmentSync.types.contains(data['type']) &&
        data['shipment_id'] == null) {
      // Legacy pushes may invalidate current-session data, but cannot route to private targets.
      _sync.schedule();
      return;
    }
    if (ShipmentSync.types.contains(data['type']) ||
        !mounted ||
        AuthService.currentSession?.isValid != true) {
      return;
    }
    // Chat has its own scoped listener. Other events still refresh the inbox.
    unawaited(_ignore(context
        .read<NotificationProvider>()
        .fetchClientNotifications(force: true)));
    if (data['type'] == 'client_statement' || data['type'] == 'payment') {
      unawaited(_ignore(context.read<ClientStatementsProvider>().refresh()));
      unawaited(
          _ignore(context.read<ProfileProvider>().fetchClientStatistics()));
      unawaited(
          _ignore(context.read<RequestsProvider>().fetchRequests(force: true)));
    }
  }

  Future<void> _refreshShipmentSurfaces() async {
    if (!mounted || AuthService.currentSession?.isValid != true) return;
    // FCM signals a change; shipment data is always reloaded from the API.
    final visible =
        (_nav?.selectedIndex ?? 4) <= 1 && _nav?.overlayPage == null;
    final instant = _home?.selectedTabIndex == 1;
    await Future.wait<void>([
      if (visible && !instant)
        _ignore(context
            .read<ShipmentProvider>()
            .getClientShipments(force: true, silent: true)),
      if (visible && instant)
        _ignore(context
            .read<ShipmentInstantprovider>()
            .getShipmentsInstant(force: true, silent: true)),
      _ignore(context
          .read<NotificationProvider>()
          .fetchClientNotifications(force: true)),
      _ignore(context.read<ProfileProvider>().fetchClientStatistics()),
    ]);
  }

  Future<void> _ignore(Future<dynamic> request) async {
    try {
      await request;
    } catch (_) {/* Providers retain their safe error state. */}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
