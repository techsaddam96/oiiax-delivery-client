import 'dart:async';

/// Coalesces a burst into one active request and, if needed, one trailing fetch.
class SessionRefreshQueue {
  SessionRefreshQueue(this.generation);
  final int Function() generation;
  Future<void>? _running;
  int? _generation;
  Future<void> Function()? _pendingFetch;

  Future<void> run(Future<void> Function() fetch, {bool trailing = true}) {
    final epoch = generation();
    if (_generation == epoch && _running != null) {
      if (trailing) _pendingFetch = fetch;
      return _running!;
    }
    _generation = epoch;
    _pendingFetch = null;
    final done = Completer<void>();
    _running = done.future;
    () async {
      try {
        var next = fetch;
        while (true) {
          await next();
          if (generation() != epoch || _pendingFetch == null) break;
          next = _pendingFetch!;
          _pendingFetch = null;
        }
        done.complete();
      } catch (error, stack) {
        done.completeError(error, stack);
      } finally {
        if (_generation == epoch) _running = null;
      }
    }();
    return done.future;
  }
}
