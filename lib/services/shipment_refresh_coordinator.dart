import 'dart:async';
import 'session_refresh_queue.dart';
import 'shipment_sync.dart';
import 'user_session_state.dart';

/// Refresh only affected surfaces; a short debounce absorbs multi-shipment bursts.
class ShipmentRefreshCoordinator {
  ShipmentRefreshCoordinator(
      {required this.refresh, required this.authenticated}) {
    _subscription = ShipmentSync.events.listen((event) {
      if (event.generation == UserSessionState.generation) schedule();
    });
    UserSessionState.register(_reset);
  }
  final Future<void> Function() refresh;
  final bool Function() authenticated;
  late final StreamSubscription<ShipmentChange> _subscription;
  final _queue = SessionRefreshQueue(() => UserSessionState.generation);
  Timer? _timer;
  bool _disposed = false;
  bool foreground = true;

  void schedule() {
    if (_disposed || !foreground || !authenticated()) return;
    _timer?.cancel();
    final epoch = UserSessionState.generation;
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (_disposed ||
          !foreground ||
          epoch != UserSessionState.generation ||
          !authenticated()) {
        return;
      }
      unawaited(_queue.run(refresh).catchError((_) {}));
    });
  }

  void resumed() {
    foreground = true;
    schedule();
  }

  void _reset() {
    _timer?.cancel();
  }

  void dispose() {
    _disposed = true;
    _reset();
    _subscription.cancel();
    UserSessionState.unregister(_reset);
  }
}
