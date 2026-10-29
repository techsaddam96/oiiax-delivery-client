import 'dart:async';
import 'dart:convert';
import 'package:blockatie/models/client_profile.dart';

import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:blockatie/provider/add_shipment_provider.dart';
import 'package:blockatie/provider/balance_history.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_conversation_provider.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/provider/filter.dart';
import 'package:blockatie/provider/header.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/login.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/notification_provider.dart';
import 'package:blockatie/provider/order_details.dart';
import 'package:blockatie/provider/orders.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/provider/statements/client_statement_details_provider.dart';
import 'package:blockatie/provider/statements/client_statements_provider.dart';
import 'package:blockatie/provider/store_statistics_provider.dart';
import 'package:blockatie/provider/time.dart';
import 'package:blockatie/provider/wallet.dart';
import 'package:blockatie/provider/withdrawal.dart';
import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:blockatie/services/store_statistics_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/chat_providers_test.dart' show FakeChatRepository;
import '../providers/client_statistics_provider_test.dart' show wallet;
import 'auth_service_secure_storage_test.dart' show MemorySecureStore;

class PendingApi implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final replies = <Completer<ResponseBody>>[];
  final _arrivals = <int, Completer<void>>{};
  Dio dio() => Dio()..httpClientAdapter = this;
  Future<void> started(int count) => requests.length >= count
      ? Future.value()
      : (_arrivals[count] ??= Completer<void>()).future;
  void reply(int index, Map<String, dynamic> body, {int status = 200}) {
    replies[index]
        .complete(ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    }));
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) {
    requests.add(options);
    final reply = Completer<ResponseBody>();
    replies.add(reply);
    _arrivals.remove(requests.length)?.complete();
    // Deliberately ignore cancellation: generation guards must still work.
    return reply.future;
  }

  @override
  void close({bool force = false}) {}
}

class SessionChat extends FakeChatRepository {
  int unread = 7;
  Completer<int>? delayedUnread;
  @override
  Future<int> getUnreadCount({CancelToken? cancelToken}) =>
      delayedUnread?.future ?? Future.value(unread);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemorySecureStore secure;
  final owned = <UserScopedNotifier>[];
  T keep<T extends UserScopedNotifier>(T value) {
    owned.add(value);
    return value;
  }

  Future<void> login(String id) => AuthService.saveApiKey('key-$id', id);
  Map<String, dynamic> profile(String id) => {
        'status': 'success',
        'profile': {
          'id': int.parse(id),
          'nclient': 'Client $id',
          'nstore': 'Store $id',
          'phclient': 'test-$id',
          'lclient': 'Address $id',
        }
      };
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'language': 'ar', 'client_onboarding_seen': true});
    secure = MemorySecureStore();
    AuthService.configureForTesting(
        secureStore: secure,
        sessionLogout: (
                {required clientId,
                required apiKey,
                required rememberToken,
                required deviceId}) async =>
            const AuthApiResult(success: true, code: 'OK', message: 'OK'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('app_badge_plus'), (_) async => false);
  });
  tearDown(() {
    for (final value in owned.reversed) {
      value.dispose();
    }
    owned.clear();
    StoreStatisticsService.resetForTesting();
    AuthService.resetForTesting();
  });

  test('A loaded -> logout -> B clean before responses -> B loaded -> A clean',
      () async {
    final profileApi = PendingApi();
    final walletApi = PendingApi();
    final shipmentApi = PendingApi();
    final notificationApi = PendingApi();
    final p = keep(ProfileProvider(
        profileDio: profileApi.dio(), statisticsDio: walletApi.dio()));
    final shipments = keep(ShipmentProvider(dio: shipmentApi.dio()));
    final notifications =
        keep(NotificationProvider(dio: notificationApi.dio()));
    final repository = SessionChat()
      ..conversationPages.add(const ChatConversationPage(conversations: [
        ChatConversation(
            conversationId: 1,
            conversationType: 'admin_client',
            title: 'A conversation',
            lastMessage: 'A only',
            lastMessageType: 'text',
            unreadCount: 7)
      ], hasMore: false));
    final chat = keep(ChatConversationsProvider(repository: repository));
    await login('1');
    final loading = Future.wait([
      p.fetchClientProfile(silent: true),
      p.fetchClientStatistics(),
      shipments.getClientShipments(),
      notifications.fetchClientNotifications(),
      chat.loadInitial(),
      chat.refreshUnreadCount()
    ]);
    await Future.wait([
      profileApi.started(1),
      walletApi.started(1),
      shipmentApi.started(1),
      notificationApi.started(1)
    ]);
    profileApi.reply(0, profile('1'));
    walletApi
        .reply(0, {'success': true, 'data': wallet(balance: '111.00 JOD')});
    shipmentApi.reply(0, {
      'status': 'success',
      'clientId': 1,
      'count': 1,
      'shipments': [
        {
          'id': 7,
          'store_id': 1,
          'recipient_name': 'A recipient',
          'policy_num': 'A-7'
        }
      ]
    });
    notificationApi.reply(0, {
      'status': 'success',
      'unread_count': 3,
      'notifications': [
        {'id': 41, 'title': 'A notification', 'message': 'A only'}
      ]
    });
    await loading;
    expect(p.profileInfo?.nstore, 'Store 1');
    expect(p.statistics?.balanceTotal, '111.00 JOD');
    expect(shipments.allShipments, hasLength(1));
    expect(notifications.notifications, hasLength(1));
    expect(chat.unreadCount, 7);
    final logout = AuthService.logout();
    // Synchronous privacy boundary, before storage/network completion.
    expect(p.profileInfo, isNull);
    expect(p.statistics, isNull);
    expect(shipments.allShipments, isEmpty);
    expect(notifications.notifications, isEmpty);
    expect(chat.conversations, isEmpty);
    expect(chat.unreadCount, 0);
    await logout;
    await login('2');
    expect(p.nameController.text, isEmpty);
    expect(notifications.unreadCount, 0);
    final next = p.fetchClientProfile(silent: true);
    await profileApi.started(2);
    expect(p.profileInfo, isNull);
    profileApi.reply(1, profile('2'));
    await next;
    expect(p.profileInfo?.nstore, 'Store 2');
    await login('1');
    expect(p.profileInfo, isNull);
    expect((await AuthService.getSession()).clientId, '1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language'), 'ar');
    expect(prefs.getBool('client_onboarding_seen'), isTrue);
    expect(prefs.getString('api_key'), isNull);
  });

  for (final target in ['profile', 'wallet', 'shipments', 'notifications']) {
    test('late A $target success cannot repopulate B or finish B loading',
        () async {
      final api = PendingApi();
      final p = keep(
          ProfileProvider(profileDio: api.dio(), statisticsDio: api.dio()));
      final s = keep(ShipmentProvider(dio: api.dio()));
      final n = keep(NotificationProvider(dio: api.dio()));
      Future<dynamic> fetch() => switch (target) {
            'profile' => p.fetchClientProfile(silent: true),
            'wallet' => p.fetchClientStatistics(),
            'shipments' => s.getClientShipments(),
            _ => n.fetchClientNotifications(),
          };
      bool loading() => switch (target) {
            'profile' => p.isLoading,
            'wallet' => p.isLoadingStatistics,
            'shipments' => s.isLoading,
            _ => n.isLoading,
          };
      await login('1');
      final old = fetch();
      await api.started(1);
      await AuthService.logout();
      await login('2');
      final current = fetch();
      await api.started(2);
      api.reply(
          0,
          target == 'profile'
              ? profile('1')
              : {
                  'status': 'success',
                  'success': true,
                  'data': wallet(),
                  'shipments': [],
                  'notifications': [
                    {'id': 1}
                  ],
                  'unread_count': 8
                });
      await old;
      expect(p.profileInfo, isNull);
      expect(p.statistics, isNull);
      expect(s.allShipments, isEmpty);
      expect(n.notifications, isEmpty);
      expect(loading(), isTrue);
      api.reply(1, {}, status: 503);
      await current;
      expect(loading(), isFalse);
      expect((await AuthService.getSession()).clientId, '2');
    });
  }

  test('old error cannot set new account errors or invalidate new credentials',
      () async {
    final api = PendingApi();
    final p = keep(ProfileProvider(profileDio: api.dio()));
    await login('1');
    final old = p.fetchClientProfile(silent: true);
    await api.started(1);
    await login('2');
    api.reply(0, {}, status: 401);
    await old;
    expect((await AuthService.getSession()).clientId, '2');
    expect(p.profileError, isNull);
  });

  test('current 401 clears state; 403, timeout, and 503 retain valid session',
      () async {
    final p = keep(ProfileProvider());
    for (final status in [403, 503, 401]) {
      await login('1');
      p.nameController.text = 'A';
      final api = PendingApi();
      final dio = protectSessionDio(api.dio());
      final request = dio.get<dynamic>('https://test.invalid/profile',
          options: Options(headers: {'X-API-KEY': 'key-1'}));
      final handled =
          request.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      await api.started(1);
      api.reply(0, {}, status: status);
      await handled;
      expect((await AuthService.getSession()).isValid, status != 401);
      expect(p.nameController.text, status == 401 ? '' : 'A');
    }
    await login('1');
    final api = PendingApi();
    final dio = protectSessionDio(api.dio());
    final request = dio.get<dynamic>('https://test.invalid/profile',
        options: Options(headers: {'X-API-KEY': 'key-1'}));
    final handled =
        request.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await api.started(1);
    api.replies[0].completeError(DioException(
        requestOptions: api.requests[0],
        type: DioExceptionType.receiveTimeout));
    await handled;
    expect((await AuthService.getSession()).isValid, isTrue);
  });

  test('current License Guard restriction clears the cached mobile session',
      () async {
    await login('1');
    final api = PendingApi();
    final dio = protectSessionDio(api.dio());
    final request = dio.get<dynamic>('https://test.invalid/profile',
        options: Options(headers: {'X-API-KEY': 'key-1'}));
    final handled =
        request.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await api.started(1);
    api.reply(0, {'code': 'LICENSE_RESTRICTED'}, status: 423);
    await handled;
    expect((await AuthService.getSession()).isValid, isFalse);
  });

  test(
      'all registered user providers reset their filters, flags, forms and selections',
      () async {
    await login('1');
    final filter = keep(FilterProvider())
      ..nameCustomer.text = 'A'
      ..isLoadingFilter = true;
    final withdrawal = keep(WithdrawalProvider())
      ..updateAmount('90 JOD')
      ..selectOption('click');
    final nav = keep(BottomNavProvider())
      ..showOverlay(const Text('A overlay'))
      ..setIndex(4);
    final time = keep(TimeProvider())..timeController.text = 'A';
    final firebase = keep(FirebaseNotificationProvider())
      ..addNotification({'isRead': false});
    final all = <UserScopedNotifier>[
      keep(AddShipmentProvider()),
      keep(BalanceHistoryProvider()),
      keep(Headerprovider()),
      keep(HomeProvider()),
      keep(OrderDetailsProvider()),
      keep(OrderStatusProvider()),
      keep(RequestsProvider()),
      keep(ShipmentInstantprovider()),
      keep(ClientStatementsProvider()),
      keep(ClientStatementDetailsProvider()),
      keep(StoreStatisticsProvider()),
      keep(WalletProvider()),
      keep(ChatLauncherProvider()),
      keep(ChatConversationProvider(
          conversationId: 3, repository: SessionChat())),
    ];
    await AuthService.clearSession();
    expect(filter.nameCustomer.text, isEmpty);
    expect(filter.isLoadingFilter, isFalse);
    expect(withdrawal.amount, '0 JOD');
    expect(withdrawal.selectedOption, 'cash');
    expect(nav.selectedIndex, 0);
    expect(nav.overlayPage, isNull);
    expect(time.timeController.text, isEmpty);
    expect(firebase.unreadCount, 0);
    for (final value in all) {
      expect(value.stateGeneration, 1);
    }
  });

  test(
      'chat late unread and list responses are ignored even when cancellation is ignored',
      () async {
    final list = Completer<ChatConversationPage>();
    final unread = Completer<int>();
    final repo = SessionChat()
      ..delayedUnread = unread
      ..listConversationsHandler = (
              {required limit, cursorLastMessageAt, cursorId, cancelToken}) =>
          list.future;
    final chat = keep(ChatConversationsProvider(repository: repo));
    await login('1');
    final a = chat.loadInitial();
    final b = chat.refreshUnreadCount();
    await login('2');
    unread.complete(99);
    list.complete(
        const ChatConversationPage(conversations: [], hasMore: false));
    await Future.wait([a, b]);
    expect(chat.unreadCount, 0);
    expect(chat.conversations, isEmpty);
    expect(chat.errorMessage, isNull);
    repo.delayedUnread = null;
    repo.unread = 2;
    await chat.refreshUnreadCount();
    expect(chat.unreadCount, 2);
  });

  test(
      'failed B login preserves A state and rapid logout/login keeps B secure key',
      () async {
    await login('1');
    final p = keep(ProfileProvider())..nameController.text = 'A';
    final loginProvider = LoginProvider(
        login: (
                {required identifier,
                required password,
                required rememberMe,
                required deviceId}) async =>
            const AuthApiResult(
                success: false,
                code: 'INVALID',
                message: 'Invalid',
                statusCode: 401),
        syncMessaging: ({required clientId, required apiKey}) async {});
    expect((await loginProvider.logIn()).success, isFalse);
    expect(p.nameController.text, 'A');
    loginProvider.dispose();
    final logout = AuthService.logout();
    final b = login('2');
    await Future.wait([logout, b]);
    expect(secure.values['client_api_key'], 'key-2');
    expect((await AuthService.getSession()).clientId, '2');
  });

  test(
      'five-minute statistics cache never crosses accounts and ignores late rating',
      () async {
    final api = PendingApi();
    StoreStatisticsService.dioFactory = api.dio;
    StoreStatisticsService.ratingLoader = () async => 4;
    await login('1');
    final first = StoreStatisticsService.getStoreStatistics();
    await api.started(1);
    api.reply(0, {'success': true, 'data': wallet(balance: '111.00 JOD')});
    final a = await first;
    expect(a, isNotNull);
    expect(identical(await StoreStatisticsService.getStoreStatistics(), a),
        isTrue);
    expect(api.requests, hasLength(1));
    await login('2');
    final b = StoreStatisticsService.getStoreStatistics();
    await api.started(2);
    api.reply(1, {'success': true, 'data': wallet(balance: '222.00 JOD')});
    expect(identical(await b, a), isFalse);
    final rating = Completer<double>();
    final ratingStarted = Completer<void>();
    StoreStatisticsService.ratingLoader = () {
      ratingStarted.complete();
      return rating.future;
    };
    final pending =
        StoreStatisticsService.getStoreStatistics(forceRefresh: true);
    await api.started(3);
    api.reply(2, {'success': true, 'data': wallet()});
    await ratingStarted.future;
    await login('1');
    rating.complete(9);
    expect(await pending, isNull);
  });

  test('late session validation cannot revoke B after A logs out', () async {
    final validation = Completer<AuthApiResult>();
    final started = Completer<void>();
    AuthService.configureForTesting(
        secureStore: secure,
        sessionValidator: ({required apiKey}) {
          started.complete();
          return validation.future;
        });
    await login('1');
    final restoring = AuthService.restoreSession();
    await started.future;
    await AuthService.clearSession();
    await login('2');
    validation.complete(const AuthApiResult(
        success: false, code: 'INVALID', message: 'Invalid', statusCode: 401));
    await restoring;
    expect((await AuthService.getSession()).clientId, '2');
  });

  test('login response arriving after logout cannot create a new session',
      () async {
    final result = Completer<AuthApiResult>();
    final started = Completer<void>();
    final provider = LoginProvider(
        login: (
            {required identifier,
            required password,
            required rememberMe,
            required deviceId}) {
          started.complete();
          return result.future;
        },
        syncMessaging: ({required clientId, required apiKey}) async {});
    final pending = provider.logIn();
    await started.future;
    await AuthService.clearSession();
    result.complete(
        const AuthApiResult(success: true, code: 'OK', message: 'OK', data: {
      'data': {'id': 2, 'api_key': 'key-2'}
    }));
    expect((await pending).code, 'SESSION_CHANGED');
    expect((await AuthService.getSession()).isValid, isFalse);
    provider.dispose();
  });

  test('disposed provider never receives a late success or error notification',
      () async {
    final api = PendingApi();
    final p = ProfileProvider(profileDio: api.dio());
    var changes = 0;
    p.addListener(() => changes++);
    await login('1');
    final pending = p.fetchClientProfile(silent: true);
    await api.started(1);
    p.dispose();
    final before = changes;
    api.reply(0, profile('1'));
    await pending;
    expect(changes, before);
    expect(p.profileInfo, isNull);
  });

  test('only current client may display private push content or a deep link',
      () async {
    await login('1');
    expect(FirebaseService.canDisplayAccountPayload({'client_id': 1}), isTrue);
    expect(
        FirebaseService.canDisplayAccountPayload(
            {'recipient_id': 1, 'recipient_role': 'driver'}),
        isFalse);
    await login('2');
    expect(FirebaseService.canDisplayAccountPayload({'client_id': 1}), isFalse);
    expect(FirebaseService.canDisplayAccountPayload({'client_id': 2}), isTrue);
    expect(FirebaseService.canDisplayAccountPayload({'type': 'chat'}), isFalse);
  });

  test('request-id retry cache is isolated across sessions', () async {
    await login('1');
    final old = RequestIdService.acquire(operation: 'edit', payload: {'id': 1});
    await login('2');
    final next =
        RequestIdService.acquire(operation: 'edit', payload: {'id': 1});
    expect(old.requestId, isNot(next.requestId));
    old.complete();
    expect(
        RequestIdService.acquire(operation: 'edit', payload: {'id': 1})
            .requestId,
        next.requestId);
  });

  testWidgets('sensitive profile widget becomes empty before B responses',
      (tester) async {
    final p = keep(ProfileProvider());
    await tester.runAsync(() => login('1'));
    p.profileInfo =
        ClientInfo.fromJson(profile('1')['profile'] as Map<String, dynamic>);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: Consumer<ProfileProvider>(
                builder: (_, value, __) =>
                    Text(value.profileInfo?.nstore ?? 'Loading')))));
    expect(find.text('Store 1'), findsOneWidget);
    await tester.runAsync(() async {
      await AuthService.logout();
      await login('2');
    });
    await tester.pump();
    expect(find.text('Store 1'), findsNothing);
    expect(find.text('Loading'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
