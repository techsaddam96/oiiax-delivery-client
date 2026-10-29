import 'dart:async';

import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/order_details.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/shipment_sync.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service_secure_storage_test.dart'
    show MemorySecureStore;

const _namesEn = {1: 'Pending', 2: 'Preparing', 3: 'Shipped'};
const _namesAr = {1: 'قيد الانتظار', 2: 'قيد التجهيز', 3: 'تم الشحن'};

OrderDetailsResponse _details(int id, int status, {int deliveryType = 2}) =>
    OrderDetailsResponse.fromJson({
      'success': true,
      'data': {
        'orderId': id,
        'currentStatusId': status,
        'currentStatus': _namesEn[status],
        'currentStatusNameEn': _namesEn[status],
        'currentStatusNameAr': _namesAr[status],
        'currentStatusMessageEn': 'Current description $status',
        'currentStatusMessageAr': 'وصف الحالة الحالية $status',
        'currentStatusTypeColor': 'info',
        'statusTimeline': [
          for (var step = 1; step <= status; step++)
            {
              'statusId': step,
              'nameEn': _namesEn[step],
              'nameAr': _namesAr[step],
              'messageEn': 'Historical description $step',
              'messageAr': 'وصف تاريخي $step',
              'timestamp': '2026-09-14 10:0$step:00',
            },
        ],
        'details': <String, dynamic>{
          'policyNumber': 'BUG03-$id',
          'deliveryType': {
            'id': deliveryType,
            'nameEn': 'Delivery',
            'nameAr': 'توصيل'
          },
        },
        'store': <String, dynamic>{},
        'driver': {'id': 9},
      },
    });

Map<String, dynamic> _event(String eventId, {int shipment = 41}) => {
      'type': 'shipment_status_updated',
      'shipment_id': '$shipment',
      'client_id': '1',
      'recipient_type': 'client',
      'event_id': eventId,
      'status_id': '3',
    };

Future<void> _mount(
  WidgetTester tester,
  Future<OrderDetailsResponse?> Function(int) loader, {
  int orderId = 41,
}) async {
  tester.view.physicalSize = const Size(480, 1400);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => BottomNavProvider(),
    child: MaterialApp(
      home: OrderDetailPage(
        key: const ValueKey('details-page'),
        orderId: orderId,
        // A stale navigation argument must never override fresh details.
        orderStatus: 'قيد التجهيز',
        detailsLoader: loader,
      ),
    ),
  ));
  await tester.pump();
}

void _expectSurfaces(WidgetTester tester, String name) {
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('shipment-current-status-chip')),
      matching: find.text(name),
    ),
    findsOneWidget,
  );
  expect(
    tester
        .widget<Text>(
            find.byKey(const ValueKey('shipment-current-status-title')))
        .data,
    name,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('shipment-current-timeline-step')),
      matching: find.text(name),
    ),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
}

Future<void> _language(WidgetTester tester, Locale locale) async {
  await tester.runAsync(() => AppLocalizations.changeLanguage(locale));
  await tester.pump();
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
    await AuthService.saveApiKey('bug03-test-token', '1');
    await AppLocalizations.initialize();
  });
  tearDown(() => AuthService.resetForTesting());

  test(
      'fresh response fields win over matching historical labels and descriptions',
      () {
    final data = _details(41, 3).data.copyWith(
          currentStatus: 'Latest shipped label',
          currentStatusNameAr: 'اسم الحالة المحدّث',
        );
    final status = data.currentStatusSnapshot;
    expect(status.statusId, 3);
    expect(status.localizedName(false), 'Latest shipped label');
    expect(status.localizedName(true), 'اسم الحالة المحدّث');
    expect(status.localizedMessage(false), 'Current description 3');
    expect(status.localizedMessage(true), 'وصف الحالة الحالية 3');
  });

  test('missing current fields fall back only to a matching status ID', () {
    final data = _details(41, 3).data.copyWith(
          currentStatus: '',
          currentStatusNameAr: '',
          currentStatusMessageEn: '',
          currentStatusMessageAr: '',
        );
    final status = data.currentStatusSnapshot;
    expect(status.localizedName(false), 'Shipped');
    expect(status.localizedName(true), 'تم الشحن');
    expect(status.localizedMessage(false), 'Historical description 3');
  });

  test(
      'unmatched history cannot provide the previous status or its description',
      () {
    final data = _details(41, 2).data.copyWith(
          currentStatusId: 42,
          currentStatus: '',
          currentStatusNameAr: '',
          currentStatusMessageEn: '',
          currentStatusMessageAr: '',
        );
    expect(data.currentStatusSnapshot.statusId, 42);
    expect(data.currentStatusSnapshot.localizedName(false), 'Status updated');
    expect(data.currentStatusSnapshot.localizedName(true), 'تم تحديث الحالة');
    expect(data.currentStatusSnapshot.localizedMessage(true), isEmpty);
  });

  test(
      'resolver preserves history order, duplicates and timestamps without mutation',
      () {
    final source = _details(41, 3).data;
    final history = [
      source.statusTimeline[1],
      source.statusTimeline[0],
      source.statusTimeline[1],
      source.statusTimeline[2]
    ];
    final data = source.copyWith(statusTimeline: history);
    data.currentStatusSnapshot;
    data.currentStatusSnapshot;
    expect(identical(data.statusTimeline, history), isTrue);
    expect(data.statusTimeline.map((e) => e.statusId), [2, 1, 2, 3]);
    expect(data.statusTimeline.map((e) => e.timestamp),
        history.map((e) => e.timestamp));
  });

  test('missing translation never borrows a label from the opposite language',
      () {
    final data = _details(41, 3).data.copyWith(
      currentStatusNameAr: '',
      currentStatusMessageAr: '',
      statusTimeline: [],
    );
    expect(data.currentStatusSnapshot.localizedName(true), 'تم تحديث الحالة');
    expect(data.currentStatusSnapshot.localizedMessage(true), isEmpty);
    expect(data.currentStatusSnapshot.localizedName(false), 'Shipped');
  });

  test('late account A response cannot replace account B current status',
      () async {
    final pendingA = Completer<OrderDetailsResponse?>();
    var requests = 0;
    final provider = OrderDetailsProvider(
        loader: (id) =>
            ++requests == 1 ? pendingA.future : Future.value(_details(id, 3)));
    addTearDown(provider.dispose);
    final a = provider.fetchOrderDetails(41);
    UserSessionState.reset(SessionResetReason.accountChanged);
    await provider.fetchOrderDetails(42);
    pendingA.complete(_details(41, 2));
    await a;
    expect(provider.orderDetails?.orderId, 42);
    expect(provider.currentStatusSnapshot?.localizedName(false), 'Shipped');
  });

  for (final arabic in [false, true]) {
    final language = arabic ? 'Arabic' : 'English';
    final names = arabic ? _namesAr : _namesEn;
    testWidgets('$language initial pending matches on all three surfaces',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _language(
          tester, arabic ? AppLocalizations.arabic : AppLocalizations.english);
      await _mount(tester, (id) async => _details(id, 1));
      _expectSurfaces(tester, names[1]!);
    });

    testWidgets('$language manual refresh pending -> preparing -> shipped',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _language(
          tester, arabic ? AppLocalizations.arabic : AppLocalizations.english);
      var status = 1;
      await _mount(tester, (id) async => _details(id, status));
      _expectSurfaces(tester, names[1]!);
      for (final next in [2, 3]) {
        status = next;
        await tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .onRefresh();
        await tester.pump();
        _expectSurfaces(tester, names[next]!);
        expect(
            tester
                .widget<Text>(find.byKey(
                    const ValueKey('shipment-current-status-description')))
                .data,
            arabic ? 'وصف الحالة الحالية $next' : 'Current description $next');
      }
    });

    testWidgets('$language FCM and resume refresh all current status surfaces',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _language(
          tester, arabic ? AppLocalizations.arabic : AppLocalizations.english);
      var status = 1;
      await _mount(tester, (id) async => _details(id, status));
      status = 2;
      expect(ShipmentSync.dispatch(_event('preparing')), isTrue);
      await tester.pump();
      _expectSurfaces(tester, names[2]!);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      status = 3;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      _expectSurfaces(tester, names[3]!);
    });
  }

  testWidgets(
      'language switch updates the same page without another API response',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loads = 0;
    await _mount(tester, (id) async {
      loads++;
      return _details(id, 3);
    });
    _expectSurfaces(tester, 'Shipped');
    await _language(tester, AppLocalizations.arabic);
    _expectSurfaces(tester, 'تم الشحن');
    expect(
        tester
            .widget<Text>(find
                .byKey(const ValueKey('shipment-current-status-description')))
            .data,
        'وصف الحالة الحالية 3');
    await _language(tester, AppLocalizations.english);
    _expectSurfaces(tester, 'Shipped');
    expect(loads, 1);
  });

  testWidgets(
      'repeat refresh keeps one current step and completed ordered history',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, (id) async => _details(id, 3));
    for (var i = 0; i < 3; i++) {
      expect(ShipmentSync.dispatch(_event('repeat-$i')), isTrue);
      await tester.pump();
      _expectSurfaces(tester, 'Shipped');
      final preparing = find.byKey(const ValueKey('shipment-history-status-2'));
      expect(preparing, findsOneWidget);
      expect(
          find.descendant(
              of: preparing, matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget);
      expect(find.descendant(of: preparing, matching: find.text('Preparing')),
          findsOneWidget);
      final pending = find.byKey(const ValueKey('shipment-history-status-1'));
      final current =
          find.byKey(const ValueKey('shipment-current-timeline-step'));
      expect(tester.getTopLeft(pending).dx,
          lessThan(tester.getTopLeft(preparing).dx));
      expect(tester.getTopLeft(preparing).dx,
          lessThan(tester.getTopLeft(current).dx));
    }
  });

  testWidgets('same page switching shipment A -> B rejects late A status',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final oldA = Completer<OrderDetailsResponse?>();
    var aLoads = 0;
    Future<OrderDetailsResponse?> loader(int id) async {
      if (id == 41 && ++aLoads > 1) return oldA.future;
      return _details(id, id == 41 ? 2 : 3);
    }

    await _mount(tester, loader);
    _expectSurfaces(tester, 'Preparing');
    ShipmentSync.dispatch(_event('late-a'));
    await tester.pump();
    await _mount(tester, loader, orderId: 42);
    _expectSurfaces(tester, 'Shipped');
    oldA.complete(_details(41, 1));
    await tester.pump();
    _expectSurfaces(tester, 'Shipped');
    expect(find.text('BUG03-42'), findsOneWidget);
    ShipmentSync.dispatch(_event('old-a-event'));
    await tester.pump();
    expect(aLoads, 2);
  });

  testWidgets(
      'page re-entry fetches current status instead of old navigation label',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var status = 2;
    Future<OrderDetailsResponse?> loader(int id) async => _details(id, status);
    await _mount(tester, loader);
    _expectSurfaces(tester, 'Preparing');
    await tester.pumpWidget(const SizedBox.shrink());
    status = 3;
    await _mount(tester, loader);
    _expectSurfaces(tester, 'Shipped');
  });

  testWidgets(
      'instant shipment uses authoritative labels, not operational stage copy',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, (id) async => _details(id, 3, deliveryType: 1));
    _expectSurfaces(tester, 'Shipped');
  });

  testWidgets(
      'new status ID is rendered from API without a hardcoded status mapping',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = _details(41, 3).data.copyWith(
      currentStatusId: 42,
      currentStatus: 'Custom current status',
      currentStatusNameAr: 'حالة جديدة',
      statusTimeline: [
        StatusTimeline(
            statusId: 42,
            nameEn: 'Old label',
            nameAr: 'اسم قديم',
            messageEn: '',
            messageAr: '',
            typeColor: 'info')
      ],
    );
    await _mount(
        tester, (_) async => OrderDetailsResponse(success: true, data: data));
    _expectSurfaces(tester, 'Custom current status');
  });
}
