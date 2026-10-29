import 'package:blockatie/services/user_session_state.dart';
import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:overlay_support/overlay_support.dart';

class HomeProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _selectedTabIndex = -1;
  }

  bool hasInternet = true;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;

  void checkInternet(BuildContext context) async {
    await _internetSubscription?.cancel();

    _internetSubscription =
        InternetConnectionChecker.instance.onStatusChange.listen((status) {
      final connected = status == InternetConnectionStatus.connected;
      hasInternet = connected;

      if (!connected) {
        if (kDebugMode) {
          debugPrint('No internet connection');
        }
        showNotification();
        notifyListeners();
      }
    });
  }

  void showNotification() {
    showSimpleNotification(
      Text(AppTranslations.getText('no_internet')),
      background: AppColors.red,
      position: NotificationPosition.top,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  int _selectedTabIndex = -1;

  int get selectedTabIndex => _selectedTabIndex;

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSelectedTabWithSubscription(int index, bool hasSubscription) {
    if (!hasSubscription && index >= 1) {
      _selectedTabIndex = 2;
    } else {
      _selectedTabIndex = index;
    }
    notifyListeners();
  }

  void resetTab() {
    _selectedTabIndex = -1;
    notifyListeners();
  }

  void resetToHome() {
    _selectedTabIndex = -1;
    notifyListeners();
  }
}
