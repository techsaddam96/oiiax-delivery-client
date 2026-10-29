import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/extensions/num_extensions.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  void _openWifiSettings() {
    if (Platform.isAndroid) {
      AppSettings.openAppSettingsPanel(AppSettingsPanelType.wifi);
    } else if (Platform.isIOS) {
      // On iOS you can only open the main Settings app,
      // direct Wi-Fi settings is restricted.
      AppSettings.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/alert.png", height: 150),
              20.ph,
              Text(
                AppLocalizations.isArabic
                    ? "لا يوجد اتصال بالانترنت"
                    : "No internet connection !!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              30.ph,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openWifiSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.isArabic ? "اتصال" : "Connect",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
