import 'dart:async';
import 'auth_services.dart';
import 'user_session_state.dart';

class ShipmentChange {
  const ShipmentChange(this.shipmentId, this.eventId, this.generation);
  final int shipmentId;
  final String eventId;
  final int generation;
}

/// FCM is an invalidation signal. Never apply status or timeline from its payload.
class ShipmentSync {
  static const types = {
    'shipment_status_updated',
    'shipment_update',
    'shipment_updated',
    'shipment_assigned',
    'driver_assigned',
    'new_shipment',
    'status_update',
  };
  static final _events = StreamController<ShipmentChange>.broadcast(sync: true);
  static Stream<ShipmentChange> get events => _events.stream;
  static final Map<String, DateTime> _seen = {};
  static int _epoch = -1;

  static int? target(Map<String, dynamic> data) {
    if (!types.contains(data['type']?.toString())) return null;
    final session = AuthService.currentSession;
    final owner = data['client_id'] ?? data['recipient_id'] ?? data['user_id'];
    final role = data['recipient_role'] ?? data['recipient_type'];
    if (session?.isValid != true ||
        owner?.toString() != session!.clientId ||
        (role != null && role != 'client')) {
      return null;
    }
    final id = int.tryParse(
        (data['shipment_id'] ?? data['item_id'])?.toString() ?? '');
    return id != null && id > 0 ? id : null;
  }

  static bool dispatch(Map<String, dynamic> data) {
    final id = target(data);
    if (id == null) return false;
    final epoch = UserSessionState.generation;
    if (_epoch != epoch) {
      _seen.clear();
      _epoch = epoch;
    }
    final now = DateTime.now();
    _seen.removeWhere(
        (_, date) => now.difference(date) > const Duration(minutes: 15));
    final eventId = data['event_id']?.toString();
    final key = eventId == null || eventId.isEmpty
        ? '${data['type']}:$id:${data['status_id'] ?? data['new_status_id']}:${now.millisecondsSinceEpoch ~/ 3000}'
        : eventId;
    if (_seen.containsKey(key)) return false;
    if (_seen.length >= 256) _seen.remove(_seen.keys.first);
    _seen[key] = now;
    _events.add(ShipmentChange(id, key, epoch));
    return true;
  }
}
