import 'package:flutter/foundation.dart';

enum SessionResetReason { logout, accountChanged, invalidSession }

class SessionChanged implements Exception {
  const SessionChanged();
}

/// One synchronous boundary for all account-owned state, including route providers.
class UserSessionState {
  UserSessionState._();

  static int _generation = 0;
  static final Set<VoidCallback> _resets = {};
  static final ValueNotifier<int> changes = ValueNotifier(0);
  static SessionResetReason? lastReason;
  static int get generation => _generation;

  static void register(VoidCallback reset) => _resets.add(reset);
  static void unregister(VoidCallback reset) => _resets.remove(reset);

  static void reset(SessionResetReason reason) {
    // Invalidate late responses before clearing any account data.
    _generation++;
    lastReason = reason;
    for (final reset in List<VoidCallback>.of(_resets)) {
      reset();
    }
    changes.value = _generation;
  }
}

abstract class UserScopedNotifier extends ChangeNotifier {
  UserScopedNotifier() {
    UserSessionState.register(resetUserState);
  }

  int _stateGeneration = 0;
  bool _stateDisposed = false;
  int get stateGeneration => _stateGeneration;
  bool acceptsState(int generation) =>
      !_stateDisposed && generation == _stateGeneration;

  Future<T> guardSession<T>(Future<T> operation, int generation) async {
    try {
      final result = await operation;
      if (!acceptsState(generation)) throw const SessionChanged();
      return result;
    } catch (_) {
      if (!acceptsState(generation)) throw const SessionChanged();
      rethrow;
    }
  }

  void resetUserState() {
    if (_stateDisposed) return;
    _stateGeneration++;
    clearUserState();
    notifyListeners();
  }

  @protected
  void clearUserState();

  @override
  void notifyListeners() {
    if (!_stateDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    UserSessionState.unregister(resetUserState);
    _stateDisposed = true;
    _stateGeneration++;
    super.dispose();
  }
}
