import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:flutter/material.dart';

/// Keeps the shell-level launcher in step with Navigator-owned modals.
///
/// The launcher is deliberately rendered above the Navigator so it survives
/// ordinary page changes.  That also means a dialog or modal bottom sheet
/// cannot obscure it by itself.  Tracking the actual top route avoids relying
/// on each caller remembering to hide and restore the launcher.
class ChatLauncherNavigationObserver extends NavigatorObserver {
  ChatLauncherNavigationObserver(this._launcherProvider);

  final ChatLauncherProvider _launcherProvider;
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  void _syncAfterNavigation() {
    final topRoute = _stack.isEmpty ? null : _stack.last;
    _launcherProvider.setModalRouteOpen(topRoute is PopupRoute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launcherProvider.syncSession();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _stack.add(route);
    _syncAfterNavigation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.remove(route);
    _syncAfterNavigation();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _stack.removeAt(index);
      } else {
        _stack[index] = newRoute;
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _syncAfterNavigation();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _stack.remove(route);
    _syncAfterNavigation();
  }
}
