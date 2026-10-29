import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/auth_services.dart';

/// Owns the shell-level visibility state for the in-app chat launcher.
///
/// The launcher is available only for a valid client session and is hidden
/// while a chat screen, dialog, or modal sheet is on top.
class ChatLauncherProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _isAuthenticated = false;
    _isAuthenticatedShellVisible = false;
    _isChatRouteOpen = false;
    _isModalRouteOpen = false;
  }

  bool _isAuthenticated = false;
  bool _isAuthenticatedShellVisible = false;
  bool _isChatRouteOpen = false;
  bool _isModalRouteOpen = false;
  bool _disposed = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get shouldShow =>
      _isAuthenticated &&
      _isAuthenticatedShellVisible &&
      !_isChatRouteOpen &&
      !_isModalRouteOpen;

  Future<void> syncSession() async {
    final sessionGeneration = stateGeneration;
    try {
      final hasValidSession =
          (await guardSession(AuthService.getSession(), sessionGeneration))
              .isValid;
      if (_isAuthenticated == hasValidSession) {
        return;
      }
      _isAuthenticated = hasValidSession;
      if (!hasValidSession) {
        _isAuthenticatedShellVisible = false;
        _isChatRouteOpen = false;
        _isModalRouteOpen = false;
      }
      _notify();
    } on SessionChanged {
      return;
    }
  }

  /// The launcher belongs to the signed-in app shell, never to splash/auth.
  void setAuthenticatedShellVisible(bool value) {
    if (_isAuthenticatedShellVisible == value) {
      return;
    }
    _isAuthenticatedShellVisible = value;
    _notify();
  }

  void setChatRouteOpen(bool value) {
    if (_isChatRouteOpen == value) {
      return;
    }
    _isChatRouteOpen = value;
    _notify();
  }

  /// The launcher is painted above the Navigator.  A dialog or modal sheet
  /// therefore needs to explicitly suppress it; otherwise the launcher can
  /// intercept touches over an active modal.
  void setModalRouteOpen(bool value) {
    if (_isModalRouteOpen == value) {
      return;
    }
    _isModalRouteOpen = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
