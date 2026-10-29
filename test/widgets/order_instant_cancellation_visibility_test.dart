import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/views/pages/home/tabs/shipment-instant/components/order_instant_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Shipment _shipment({required int statusId, int? driverId}) {
  return Shipment.fromJson({
    'id': 701,
    'shipment_date': '2026-10-27',
    'policy_num': 'QA-MOBILE-701',
    'recipient_name': 'QA receiver',
    'recipient_phone': '0790000000',
    'store_id': 1,
    'governorate_id': 1,
    'delivery_address': 'QA address',
    'driver_id': driverId,
    'delivery_type_id': 1,
    'delivery_type_name_en': 'Instant',
    'shipment_cost': '0.00',
    'delivery_cost': '0.00',
    'percent_driver': 0,
    'shipment_note': '',
    'employee_id': 0,
    'product_type_id': 1,
    'shipment_status': 1,
    'accounting_shipment': 0,
    'returned_shipment': 0,
    'created_at': '2026-10-27 10:00:00',
    'updated_at': '2026-10-27 10:00:00',
    'shipment_status_id': statusId,
    'status_name_en': 'In progress',
    'status_name_ar': 'قيد المتابعة',
    'driver_name': driverId == null ? null : 'QA driver',
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required Shipment shipment,
  required VoidCallback onCancel,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OrderInstantTile(
          shipment: shipment,
          typeLabel: 'Instant',
          statusLabel: 'In progress',
          stageLabel: 'In progress',
          createdLabel: 'Today',
          canCancel: true,
          isBusy: false,
          onViewDetails: () {},
          onCancelShipment: onCancel,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cancellation is hidden after driver assignment', (tester) async {
    var calls = 0;
    await _mount(
      tester,
      shipment: _shipment(statusId: 3, driverId: 55),
      onCancel: () => calls++,
    );

    final cancel = find.byTooltip('Cancel');
    expect(cancel, findsNothing);
    expect(calls, 0);
  });

  testWidgets('cancellation is hidden after pickup/handover', (tester) async {
    await _mount(
      tester,
      shipment: _shipment(statusId: 5, driverId: 55),
      onCancel: () {},
    );

    expect(find.byTooltip('Cancel'), findsNothing);
  });

  testWidgets('cancellation remains hidden for a final shipment',
      (tester) async {
    await _mount(
      tester,
      shipment: _shipment(statusId: 7, driverId: 55),
      onCancel: () {},
    );

    expect(find.byTooltip('Cancel'), findsNothing);
  });

  testWidgets('cancellation is visible only for a pending unassigned shipment',
      (tester) async {
    await _mount(
      tester,
      shipment: _shipment(statusId: 1),
      onCancel: () {},
    );

    expect(find.byTooltip('Cancel'), findsOneWidget);
  });
}
