import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/utils/client_shipment_cancellation_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Shipment shipment({
    int id = 31,
    int statusId = 1,
    int visibility = 1,
    int deliveryTypeId = 1,
    int? driverId,
    String? driverName,
  }) {
    return Shipment.fromJson(<String, dynamic>{
      'shipment_id': id,
      'shipment_status_id': statusId,
      'shipment_status': visibility,
      'delivery_type_id': deliveryTypeId,
      if (driverId != null) 'driver_id': driverId,
      if (driverName != null) 'dname': driverName,
    });
  }

  OrderDetailsResponse details({
    int orderId = 31,
    int statusId = 1,
    int driverId = 0,
    bool success = true,
    bool includeCancellation = true,
    bool cancellationAllowed = true,
  }) {
    return OrderDetailsResponse.fromJson(<String, dynamic>{
      'success': success,
      'data': <String, dynamic>{
        'orderId': orderId,
        'currentStatusId': statusId,
        'driver': <String, dynamic>{'id': driverId},
        if (includeCancellation)
          'cancellation': <String, dynamic>{
            'allowed': cancellationAllowed,
            'stage': 'created',
            'fee_if_cancelled': 0,
          },
      },
    });
  }

  group('ClientShipmentCancellationEligibility list guard', () {
    test('allows only a newly created, unassigned instant shipment', () {
      expect(
        ClientShipmentCancellationEligibility.isListEligible(shipment()),
        isTrue,
      );
    });

    test('fails closed for every non-pending or hidden state', () {
      for (final statusId in <int>[0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) {
        expect(
          ClientShipmentCancellationEligibility.isListEligible(
            shipment(statusId: statusId),
          ),
          isFalse,
          reason: 'status $statusId must not expose cancellation',
        );
      }

      expect(
        ClientShipmentCancellationEligibility.isListEligible(
          shipment(visibility: 0),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isListEligible(
          shipment(deliveryTypeId: 2),
        ),
        isFalse,
      );
    });

    test('hides cancellation for either form of driver assignment', () {
      expect(
        ClientShipmentCancellationEligibility.isListEligible(
          shipment(driverId: 7),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isListEligible(
          shipment(driverName: 'Assigned driver'),
        ),
        isFalse,
      );
    });
  });

  group('ClientShipmentCancellationEligibility detail guard', () {
    test('requires the fresh server preview for the same pending shipment', () {
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(),
        ),
        isTrue,
      );
    });

    test('fails closed for stale, assigned, missing, or refused details', () {
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: null,
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(orderId: 32),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(statusId: 2),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(driverId: 7),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(includeCancellation: false),
        ),
        isFalse,
      );
      expect(
        ClientShipmentCancellationEligibility.isDetailsEligible(
          shipmentId: 31,
          response: details(cancellationAllowed: false),
        ),
        isFalse,
      );
    });
  });
}
