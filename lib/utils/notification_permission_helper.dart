import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blockatie/utils/localization/translations.dart';

class NotificationPermissionHelper {
  // Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Show permission dialog if needed
  static Future<bool> showPermissionDialogIfNeeded(BuildContext context) async {
    final isGranted = await isNotificationPermissionGranted();

    if (isGranted) {
      return true;
    }

    // Show custom dialog to explain why we need permission
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText('enable_notifications')),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay updated with your shipment status!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'We\'ll send you notifications about:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Shipment status updates'),
            Text('• New shipment assignments'),
            Text('• Payment confirmations'),
            Text('• Important announcements'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppTranslations.getText('not_now')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppTranslations.getText('enable')),
          ),
        ],
      ),
    );

    if (result == true) {
      return await requestNotificationPermission();
    }

    return false;
  }

  // Open app settings if permission is permanently denied
  static Future<void> openAppSettingsIfNeeded() async {
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}
