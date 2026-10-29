import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/utils/instant_shipment_progress.dart';

/// The client-side cancellation boundary for instant shipments.
///
/// The list response is authoritative for the immediately-rendered state, but
/// it does not include the server's cancellation preview.  A caller must also
/// pass [isDetailsEligible] before exposing or executing the action.  Unknown
/// states deliberately fail closed.
class ClientShipmentCancellationEligibility {
  const ClientShipmentCancellationEligibility._();

  /// `1` is the server's created/pending shipment state.  Any later state can
  /// mean a driver accepted or an operator assigned the shipment, so it is not
  /// cancellable from the client app.
  static const int pendingStatusId = 1;

  static bool isListEligible(Shipment shipment) {
    return shipment.id > 0 &&
        InstantShipmentProgressHelper.isInstantShipment(shipment) &&
        shipment.shipmentStatus == 1 &&
        shipment.shipmentStatusId == pendingStatusId &&
        !InstantShipmentProgressHelper.hasAssignedDriver(shipment);
  }

  /// Confirms the latest detail response still represents the same pending,
  /// unassigned shipment and that the server permits cancellation.
  static bool isDetailsEligible({
    required int shipmentId,
    required OrderDetailsResponse? response,
  }) {
    final details = response?.data;
    return response?.success == true &&
        details != null &&
        details.orderId == shipmentId &&
        details.currentStatusId == pendingStatusId &&
        details.driver.id <= 0 &&
        details.cancellation?.allowed == true;
  }
}
