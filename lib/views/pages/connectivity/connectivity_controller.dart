import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityController {
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    isInternetConnected(result.first);
    _subscription ??= _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      isInternetConnected(result.first);
    });
  }

  bool isInternetConnected(ConnectivityResult? result) {
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
      return false;
    } else if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      isConnected.value = true;
      return true;
    }
    return false;
  }

  void dispose() {
    _subscription?.cancel();
    isConnected.dispose();
  }
}
