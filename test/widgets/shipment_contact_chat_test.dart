import 'dart:async';

import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/chat/conversation_page.dart';
import 'package:blockatie/views/pages/chat/conversations_page.dart';
import 'package:blockatie/views/pages/home/tabs/all-shipments/table_all_shipment.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/floating_chat_bubble.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service_secure_storage_test.dart'
    show MemorySecureStore;

OrderDetailsResponse _details(int id) => OrderDetailsResponse.fromJson({
      'success': true,
      'data': {
        'orderId': id,
        'currentStatusId': 6,
        'currentStatus': 'Delivered',
        'currentStatusNameAr': 'تم التسليم',
        'details': <String, dynamic>{'policyNumber': 'QA-BUG04-$id'},
        'store': <String, dynamic>{},
      },
    });

ChatConversationReadyResult _ready(int shipment,
        {bool created = false, String type = 'shipment_client'}) =>
    ChatConversationReadyResult(
        created: created,
        conversation: ChatConversation(
          conversationId: 700 + shipment,
          conversationType: type,
          shipmentId: shipment,
          policyNum: 'QA-BUG04-$shipment',
          title: 'Operations',
          lastMessage: '',
          lastMessageType: 'text',
          unreadCount: 0,
        ));

class _Repository extends Fake implements ChatRepository {
  final requests = <int>[];
  final messageRequests = <int>[];
  int listRequests = 0;
  Future<ChatConversationReadyResult> Function(int)? handler;
  @override
  Future<ChatConversationReadyResult> getOrCreateShipmentConversation(
      {required int shipmentId, CancelToken? cancelToken}) {
    requests.add(shipmentId);
    return handler?.call(shipmentId) ?? Future.value(_ready(shipmentId));
  }

  @override
  Future<ChatMessagesPage> getMessages(
      {required int conversationId,
      int? beforeMessageId,
      int limit = 30,
      CancelToken? cancelToken}) async {
    messageRequests.add(conversationId);
    return const ChatMessagesPage(messages: [], hasMore: false);
  }

  @override
  Future<ChatNewMessagesPage> getNewMessages(
          {required int conversationId,
          required int afterMessageId,
          int limit = 50,
          CancelToken? cancelToken}) async =>
      const ChatNewMessagesPage(
          messages: [], latestMessageId: 0, hasMore: false);
  @override
  Future<ChatConversationPage> listConversations(
      {int limit = 20,
      DateTime? cursorLastMessageAt,
      int? cursorId,
      CancelToken? cancelToken}) async {
    listRequests++;
    return const ChatConversationPage(conversations: [], hasMore: false);
  }

  @override
  Future<int> getUnreadCount({CancelToken? cancelToken}) async => 0;
}

class _Shipments extends ShipmentProvider {
  _Shipments() {
    shipmentsResponse = ShipmentsResponse(
        status: 'success',
        message: '',
        clientId: 1,
        count: 1,
        shipments: [
          Shipment.fromJson({
            'shipment_id': 41,
            'policy_num': 'QA-BUG04-41',
            'shipment_status_id': 6,
            'status_name_en': 'Delivered',
            'recipient_name': 'QA only',
            'delivery_type_id': 2,
          })
        ]);
  }
  @override
  bool get hasLoaded => true;
}

Future<void> _mount(
  WidgetTester tester,
  _Repository repository, {
  bool list = false,
  int id = 41,
  Future<OrderDetailsResponse?> Function(int)? loader,
}) async {
  tester.view.physicalSize = const Size(480, 1800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<BottomNavProvider>(
          create: (_) => BottomNavProvider()..setIndex(1)),
      ChangeNotifierProvider<ShipmentProvider>(create: (_) => _Shipments()),
      ChangeNotifierProvider<ChatConversationsProvider>(
          create: (_) => ChatConversationsProvider(repository: repository)),
    ],
    child: MaterialApp(
        home: Scaffold(
            body: list
                ? TableAllShipment(
                    chatRepository: repository,
                    detailsLoader: loader ?? (id) async => _details(id))
                : OrderDetailPage(
                    key: const ValueKey('details'),
                    orderId: id,
                    detailsLoader: loader ?? (id) async => _details(id),
                    chatRepository: repository))),
  ));
  await tester.pumpAndSettle();
}

Finder _button({bool list = false}) => find.byKey(ValueKey(
    list ? 'shipment-contact-company-41' : 'shipment-details-contact-company'));
Future<void> _tap(WidgetTester tester,
    {bool list = false, bool settle = true}) async {
  await tester.ensureVisible(_button(list: list));
  await tester.tap(_button(list: list));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void _expectChat(WidgetTester tester, int shipmentId) {
  final page = tester.widget<ConversationPage>(find.byType(ConversationPage));
  expect(page.conversationId, 700 + shipmentId);
  expect(page.shipmentId, shipmentId);
  expect(page.policyNum, 'QA-BUG04-$shipmentId');
  expect(find.textContaining('QA-BUG04-$shipmentId'), findsWidgets);
  expect(find.byType(SupportAssistancePage), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    // These tests assert English copy; Arabic is the app default.
    SharedPreferences.setMockInitialValues({'language_code': 'en'});
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('app_badge_plus'), (_) async => false);
    await AuthService.saveApiKey('bug04-test-token', '1');
    await AppLocalizations.initialize();
  });
  tearDown(() => AuthService.resetForTesting());

  testWidgets(
      'actual delivered list Contact Company opens shipment chat, never generic contact',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final detailRequests = <int>[];
    await _mount(tester, repository, list: true, loader: (id) async {
      detailRequests.add(id);
      return _details(id);
    });
    await _tap(tester, list: true);
    expect(detailRequests, [41]);
    expect(repository.requests, [41]);
    expect(repository.messageRequests, [741]);
    _expectChat(tester, 41);
    await tester.pumpWidget(const SizedBox());
  });

  for (final created in [false, true]) {
    testWidgets(
        'delivered details opens ${created ? 'created' : 'existing'} conversation',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository()
        ..handler = (id) async => _ready(id, created: created);
      await _mount(tester, repository);
      await _tap(tester);
      _expectChat(tester, 41);
      expect(repository.requests, [41]);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('rapid double tap issues one request and navigation',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<ChatConversationReadyResult>();
    final repository = _Repository()..handler = (_) => pending.future;
    await _mount(tester, repository, list: true);
    await _tap(tester, list: true, settle: false);
    await tester.tap(_button(list: true));
    await tester.pump();
    expect(repository.requests, [41]);
    expect(tester.widget<FilledButton>(_button(list: true)).onPressed, isNull);
    pending.complete(_ready(41));
    await tester.pumpAndSettle();
    _expectChat(tester, 41);
    expect(find.byType(ConversationPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final failure in <ChatException>[
    const ChatAuthenticationException(),
    const ChatAuthorizationException(),
    const ChatServerException(),
  ]) {
    testWidgets(
        '${failure.runtimeType} shows retryable error without leaving details',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository()..handler = (_) async => throw failure;
      await _mount(tester, repository);
      await _tap(tester);
      expect(find.byType(ConversationPage), findsNothing);
      expect(find.byType(OrderDetailPage), findsOneWidget);
      expect(find.byType(SupportAssistancePage), findsNothing);
      expect(find.text('Unable to open shipment chat. Please try again.'),
          findsOneWidget);
      repository.handler = null;
      await _tap(tester);
      _expectChat(tester, 41);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final reason in [
    SessionResetReason.logout,
    SessionResetReason.accountChanged
  ]) {
    testWidgets('late account A chat-open is ignored after $reason',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<ChatConversationReadyResult>();
      final repository = _Repository()..handler = (_) => pending.future;
      await _mount(tester, repository);
      await _tap(tester, settle: false);
      UserSessionState.reset(reason);
      await tester.pump();
      if (reason == SessionResetReason.accountChanged) {
        repository.handler = null;
        await _mount(tester, repository, id: 42);
        await _tap(tester);
        _expectChat(tester, 42);
      }
      pending.complete(_ready(41));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate(
              (w) => w is ConversationPage && w.shipmentId == 41),
          findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'changing shipment while opening rejects old response and allows new request',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<ChatConversationReadyResult>();
    final repository = _Repository()
      ..handler = (id) => id == 41 ? pending.future : Future.value(_ready(id));
    await _mount(tester, repository);
    await _tap(tester, settle: false);
    await _mount(tester, repository, id: 42);
    await _tap(tester);
    pending.complete(_ready(41));
    await tester.pumpAndSettle();
    _expectChat(tester, 42);
    expect(repository.requests, [41, 42]);
    await tester.pumpWidget(const SizedBox());
  });

  for (final response in [_ready(999), _ready(41, type: 'shipment_driver')]) {
    testWidgets(
        'mismatched shipment/type ${response.conversation.conversationType}/${response.conversation.shipmentId} cannot navigate',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository()..handler = (_) async => response;
      await _mount(tester, repository);
      await _tap(tester);
      expect(find.byType(ConversationPage), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('wrong authoritative order ID never reaches chat get/create',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _mount(tester, repository,
        list: true, loader: (_) async => _details(999));
    await _tap(tester, list: true);
    expect(repository.requests, isEmpty);
    expect(find.byType(ConversationPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving and reopening uses the same returned conversation ID',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _mount(tester, repository, list: true);
    await _tap(tester, list: true);
    _expectChat(tester, 41);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await _tap(tester, list: true);
    _expectChat(tester, 41);
    expect(repository.requests, [41, 41]);
    expect(repository.messageRequests, [741, 741]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'existing global floating chat still opens the conversations list',
      (tester) async {
    final repository = _Repository();
    final launcher = ChatLauncherProvider();
    await launcher.syncSession();
    launcher.setAuthenticatedShellVisible(true);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ChatLauncherProvider>.value(value: launcher),
          ChangeNotifierProvider<ChatConversationsProvider>(
              create: (_) => ChatConversationsProvider(repository: repository)),
        ],
        child: MaterialApp(
            navigatorKey: Nav.key,
            builder: (context, child) =>
                Stack(children: [child!, const FloatingChatBubble()]),
            home: const Scaffold(body: Text('Home')))));
    await tester.pump();
    await tester.tap(find.byType(FloatingChatBubble));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(ConversationsPage), findsOneWidget);
    expect(repository.listRequests, 1);
    expect(repository.requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
    launcher.dispose();
  });
}
