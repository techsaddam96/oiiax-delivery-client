import 'package:blockatie/services/user_session_state.dart';
import 'package:flutter/material.dart';

class BottomNavProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _selectedIndex = 0;
    _overlayPage = null;
  }

  int _selectedIndex = 0;
  Widget? _overlayPage;

  int get selectedIndex => _selectedIndex;
  Widget? get overlayPage => _overlayPage;

  void setIndex(int index) {
    _selectedIndex = index;

    // ❗ Clear overlay whenever tab is changed
    _overlayPage = null;
    notifyListeners();
  }

  void showOverlay(Widget page) {
    _overlayPage = page;
    notifyListeners();
  }

  void clearOverlay() {
    _overlayPage = null;
    notifyListeners();
  }
}
