import 'dart:async';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/provider/order_details.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/session_refresh_queue.dart';
import 'package:blockatie/services/shipment_sync.dart';
import 'package:blockatie/services/shipment_details_sync.dart';
import 'package:blockatie/services/shipment_refresh_coordinator.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service_secure_storage_test.dart' show MemorySecureStore;
import 'account_isolation_test.dart' show PendingApi;

Map<String, dynamic> event(
        {int shipment = 41,
        String owner = '1',
        String id = 'event-1',
        String type = 'shipment_status_updated'}) =>
    {
      'type': type,
      'shipment_id': '$shipment',
      'client_id': owner,
      'recipient_type': 'client',
      'event_id': id,
      'status_id': '3',
    };
OrderDetailsResponse details(int id, int status) =>
    OrderDetailsResponse.fromJson({
      'success': true,
      'data': {
        'orderId': id,
        'currentStatusId': status,
        'currentStatus': 'Status $status',
        'statusTimeline': [
          for (var i = 1; i <= status; i++)
            {
              'statusId': i,
              'nameEn': 'Status $i',
              'nameAr': 'حالة $i',
              'timestamp': '2026-09-10 10:0$i:00',
            }
        ],
        'details': <String, dynamic>{},
        'store': <String, dynamic>{},
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('app_badge_plus'), (_) async => false);
    await AuthService.saveApiKey('test-key-1', '1');
  });
  tearDown(() => AuthService.resetForTesting());

  testWidgets(
      'foreground event refreshes scoped surfaces and duplicates coalesce',
      (tester) async {
    var fetches = 0;
    final sync = ShipmentRefreshCoordinator(
        authenticated: () => true,
        refresh: () async {
          fetches++;
        });
    addTearDown(sync.dispose);
    expect(ShipmentSync.dispatch(event()), isTrue);
    expect(ShipmentSync.dispatch(event()), isFalse);
    ShipmentSync.dispatch(event(id: 'event-2'));
    await tester.pump(const Duration(milliseconds: 301));
    expect(fetches, 1);
  });
  testWidgets('unrelated notification does not refresh shipments',
      (tester) async {
    var fetches = 0;
    final sync = ShipmentRefreshCoordinator(
        authenticated: () => true,
        refresh: () async {
          fetches++;
        });
    addTearDown(sync.dispose);
    expect(ShipmentSync.dispatch(event(type: 'chat')), isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(fetches, 0);
  });
  testWidgets('resume fallback refreshes once; background events do not fetch',
      (tester) async {
    var fetches = 0;
    final sync = ShipmentRefreshCoordinator(
        authenticated: () => true,
        refresh: () async {
          fetches++;
        });
    addTearDown(sync.dispose);
    sync.foreground = false;
    ShipmentSync.dispatch(event());
    await tester.pump(const Duration(seconds: 1));
    expect(fetches, 0);
    sync.resumed();
    await tester.pump(const Duration(milliseconds: 301));
    expect(fetches, 1);
  });
  test('only event A refreshes open details A, never event B', () async {
    var fetches = 0;
    final provider =
        OrderDetailsProvider(loader: (id) async => details(id, ++fetches));
    final sync = ShipmentDetailsSync(
        shipmentId: 41,
        visible: () => true,
        refresh: () =>
            provider.fetchOrderDetails(41, force: true, silent: true));
    addTearDown(sync.dispose);
    addTearDown(provider.dispose);
    await provider.fetchOrderDetails(41);
    ShipmentSync.dispatch(event(shipment: 42));
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 1);
    ShipmentSync.dispatch(event(id: 'event-A'));
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 2);
    expect(provider.currentStatusId, 2);
    expect(provider.statusTimeline.map((e) => e.statusId), [1, 2]);
  });
  test(
      'details stop syncing when hidden/background/disposed, with no global polling',
      () {
    var fetches = 0;
    var visible = false;
    final sync = ShipmentDetailsSync(
        shipmentId: 41,
        visible: () => visible,
        refresh: () async {
          fetches++;
        });
    ShipmentSync.dispatch(event());
    expect(fetches, 0);
    visible = true;
    sync.foreground = false;
    ShipmentSync.dispatch(event(id: '2'));
    expect(fetches, 0);
    sync.foreground = true;
    sync.refreshIfVisible();
    expect(fetches, 1);
    sync.dispose();
    ShipmentSync.dispatch(event(id: '3'));
    expect(fetches, 1);
  });
  test('reopening details fetches new authoritative state', () async {
    var status = 2;
    final first =
        OrderDetailsProvider(loader: (id) async => details(id, status));
    await first.fetchOrderDetails(41);
    first.dispose();
    status = 3;
    final reopened =
        OrderDetailsProvider(loader: (id) async => details(id, status));
    addTearDown(reopened.dispose);
    await reopened.fetchOrderDetails(41);
    expect(reopened.currentStatusId, 3);
    expect(reopened.statusTimeline.length, 3);
  });
  test('late response A and old A event cannot enter account B', () async {
    final pending = Completer<OrderDetailsResponse?>();
    final provider = OrderDetailsProvider(loader: (_) => pending.future);
    addTearDown(provider.dispose);
    final request = provider.fetchOrderDetails(41);
    await AuthService.saveApiKey('test-key-2', '2');
    expect(ShipmentSync.dispatch(event(owner: '1')), isFalse);
    pending.complete(details(41, 3));
    await request;
    expect(provider.orderDetails, isNull);
    expect(ShipmentSync.target(event(owner: '1')), isNull);
    expect(ShipmentSync.target(event(owner: '2')), 41);
  });
  test('logged out and missing-owner events cannot target a private shipment',
      () {
    final data = event()..remove('client_id');
    expect(ShipmentSync.target(data), isNull);
    UserSessionState.reset(SessionResetReason.logout);
    // Authenticated identity is explicitly checked as well as the generation.
    AuthService.resetForTesting();
    expect(ShipmentSync.target(event()), isNull);
  });
  test('request coalescing retains one trailing update', () async {
    final queue = SessionRefreshQueue(() => 1);
    var calls = 0;
    final pending = Completer<void>();
    Future<void> fetch() async {
      if (++calls == 1) await pending.future;
    }

    final first = queue.run(fetch);
    final second = queue.run(fetch);
    queue.run(fetch);
    expect(calls, 1);
    pending.complete();
    await Future.wait([first, second]);
    expect(calls, 2);
  });

  test(
      'refresh arriving during pagination runs the newest action, not another page fetch',
      () async {
    final queue = SessionRefreshQueue(() => 1);
    final pending = Completer<void>();
    final actions = <String>[];
    final page = queue.run(() async {
      actions.add('page');
      await pending.future;
    });
    final refresh = queue.run(() async {
      actions.add('refresh');
    });
    pending.complete();
    await Future.wait([page, refresh]);
    expect(actions, ['page', 'refresh']);
  });

  test('order ownership rejection removes previously displayed details',
      () async {
    var permitted = true;
    final provider = OrderDetailsProvider(
        loader: (id) async => permitted ? details(id, 2) : null);
    addTearDown(provider.dispose);
    await provider.fetchOrderDetails(41);
    expect(provider.orderDetails, isNotNull);
    permitted = false;
    await provider.fetchOrderDetails(41, force: true, silent: true);
    expect(provider.orderDetails, isNull);
    expect(provider.error, 'LOAD_FAILED');
  });
  test(
      'details request in flight receives a trailing status and timeline refresh',
      () async {
    final first = Completer<OrderDetailsResponse?>();
    var calls = 0;
    final provider = OrderDetailsProvider(
        loader: (id) =>
            ++calls == 1 ? first.future : Future.value(details(id, 3)));
    addTearDown(provider.dispose);
    final old = provider.fetchOrderDetails(41);
    final updated = provider.fetchOrderDetails(41, force: true, silent: true);
    first.complete(details(41, 2));
    await Future.wait([old, updated]);
    expect(calls, 2);
    expect(provider.currentStatusId, 3);
    expect(provider.statusTimeline.length, 3);
  });
  test('opening different details while A loads cannot publish A into B',
      () async {
    final first = Completer<OrderDetailsResponse?>();
    final provider = OrderDetailsProvider(
        loader: (id) => id == 41 ? first.future : Future.value(details(id, 3)));
    addTearDown(provider.dispose);
    final old = provider.fetchOrderDetails(41);
    final latest = provider.fetchOrderDetails(42);
    first.complete(details(41, 2));
    await Future.wait([old, latest]);
    expect(provider.orderDetails?.orderId, 42);
  });
  test('list refresh replaces card status without duplicate shipments',
      () async {
    final api = PendingApi();
    final provider = ShipmentProvider(dio: api.dio());
    addTearDown(provider.dispose);
    Map<String, dynamic> body(int status) => {
          'status': 'success',
          'clientId': 1,
          'count': 1,
          'shipments': [
            {
              'shipment_id': 41,
              'policy_num': 'TEST-41',
              'order_status_id': status
            }
          ]
        };
    final initial = provider.getClientShipments();
    await api.started(1);
    api.reply(0, body(2));
    await initial;
    final refresh = provider.getClientShipments(force: true, silent: true);
    expect(provider.isLoading, isFalse);
    await api.started(2);
    api.reply(1, body(3));
    await refresh;
    expect(provider.allShipments.length, 1);
    expect(provider.allShipments.single.shipmentStatusId, 3);
  });
  test('inbox reload uses server unread count and replaces duplicate cards',
      () async {
    final api = PendingApi();
    final provider = NotificationProvider(dio: api.dio());
    addTearDown(provider.dispose);
    final initial = provider.fetchClientNotifications(force: true);
    await api.started(1);
    api.reply(0, {
      'status': 'success',
      'unread_count': 1,
      'notifications': [
        {'id': 71, 'type': 'shipment_status_updated', 'item_id': 41}
      ]
    });
    await initial;
    final refresh = provider.fetchClientNotifications(force: true);
    await api.started(2);
    api.reply(1, {
      'status': 'success',
      'unread_count': 1,
      'notifications': [
        {'id': 71, 'type': 'shipment_status_updated', 'item_id': 41}
      ]
    });
    await refresh;
    expect(provider.unreadCount, 1);
    expect(provider.notifications.length, 1);
  });
  testWidgets(
      'queued event cancelled on session change or coordinator disposal',
      (tester) async {
    var fetches = 0;
    final sync = ShipmentRefreshCoordinator(
        authenticated: () => true,
        refresh: () async {
          fetches++;
        });
    ShipmentSync.dispatch(event());
    UserSessionState.reset(SessionResetReason.accountChanged);
    await tester.pump(const Duration(seconds: 1));
    expect(fetches, 0);
    sync.schedule();
    sync.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(fetches, 0);
  });
}
