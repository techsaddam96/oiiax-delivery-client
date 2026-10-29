import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';

class AppUtils {
  static void sucessToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static void errorToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // Adaptive Alert Dialog Methods (Snackbar Replacements)

  /// Shows a success alert dialog
  static void showSuccessDialog(String message, {String? title}) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showSuccess(
      context: context,
      title: title ?? AppTranslations.getText('success'),
      content: message,
      buttonText: AppTranslations.getText('ok'),
    );
  }

  /// Shows an error alert dialog
  static void showErrorDialog(String message, {String? title}) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showError(
      context: context,
      title: title ?? 'Error',
      content: message,
      buttonText: AppTranslations.getText('ok'),
    );
  }

  /// Shows a warning alert dialog
  static void showWarningDialog(String message, {String? title}) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showWarning(
      context: context,
      title: title ?? 'Warning',
      content: message,
      primaryButtonText: AppTranslations.getText('ok'),
      onPrimaryPressed: () => Navigator.of(context).pop(),
    );
  }

  /// Shows an info alert dialog
  static void showInfoDialog(String message, {String? title}) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showInfo(
      context: context,
      title: title ?? 'Information',
      content: message,
      buttonText: AppTranslations.getText('ok'),
    );
  }

  /// Shows a confirmation dialog with custom actions
  static void showConfirmationDialog({
    required String message,
    String? title,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showConfirmation(
      context: context,
      title: title ?? 'Confirm',
      content: message,
      primaryButtonText: confirmText ?? 'Yes',
      secondaryButtonText: cancelText ?? 'Cancel',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        onConfirm?.call();
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
        onCancel?.call();
      },
    );
  }

  /// Shows a success dialog without buttons
  static void showSuccessNoButton(String message, {String? title}) {
    final context = Nav.key.currentState?.context;
    if (context == null) return;

    CustomAlert.showSuccessNoButton(
      context: context,
      title: title ?? 'Success',
      content: message,
    );
  }

  // Legacy toast methods (kept for backward compatibility)
  static void showSuccessSnackbar(String message) {
    showSuccessDialog(message);
  }

  static void showErrorSnackbar(String message) {
    showErrorDialog(message);
  }

  static void showWarningSnackbar(String message) {
    showWarningDialog(message);
  }

  static void showInfoSnackbar(String message) {
    showInfoDialog(message);
  }

  static void showLoaderDialog() {
    showDialog(
      context: Nav.key.currentState!.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            width: 80,
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  static void hideLoaderDialog() {
    Navigator.pop(
      Nav.key.currentState!.context,
    );
  }
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  if (!GetUtils.isEmail(value)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
