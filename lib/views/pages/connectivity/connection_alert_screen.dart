import 'package:blockatie/views/pages/connectivity/connectivity_controller.dart';
import 'package:blockatie/views/pages/connectivity/no_internet_screen.dart';
import 'package:flutter/material.dart';

class ConnectionAlert extends StatefulWidget {
  const ConnectionAlert({super.key});

  @override
  State<ConnectionAlert> createState() => _ConnectionAlertState();
}

class _ConnectionAlertState extends State<ConnectionAlert> {
  ConnectivityController connectivityController = ConnectivityController();

  @override
  void initState() {
    super.initState();
    connectivityController.init();
  }

  @override
  void dispose() {
    connectivityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ValueListenableBuilder(
          valueListenable: connectivityController.isConnected,
          builder: (context, value, child) {
            if (value) {
              return const SizedBox();
            } else {
              return const NoInternetScreen();
            }
          }),
    );
  }
}
