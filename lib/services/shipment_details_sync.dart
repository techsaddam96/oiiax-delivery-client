import 'dart:async';
import 'auth_services.dart';
import 'shipment_sync.dart';
import 'user_session_state.dart';

class ShipmentDetailsSync {
  ShipmentDetailsSync(
      {required this.shipmentId,
      required this.visible,
      required this.refresh}) {
    _events = ShipmentSync.events.listen((event) {
      if (event.shipmentId == shipmentId && event.generation == _epoch) {
        refreshIfVisible();
      }
    });
  }
  final int shipmentId;
  final bool Function() visible;
  final Future<void> Function() refresh;
  final int _epoch = UserSessionState.generation;
  late final StreamSubscription<ShipmentChange> _events;
  bool foreground = true;
  bool _disposed = false;

  void refreshIfVisible() {
    if (_disposed ||
        !foreground ||
        !visible() ||
        _epoch != UserSessionState.generation ||
        AuthService.currentSession?.isValid != true) {
      return;
    }
    unawaited(refresh().catchError((_) {}));
  }

  void dispose() {
    _disposed = true;
    _events.cancel();
  }
}
