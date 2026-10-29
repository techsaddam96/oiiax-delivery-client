import 'package:blockatie/utils/app_utils.dart';

/// This file demonstrates how to convert SnackBars to Adaptive Alert Dialogs
///
/// The new adaptive alert dialogs provide:
/// - Better visual hierarchy with icons and titles
/// - Automatic dismissal with configurable timeouts
/// - Consistent styling across the app
/// - Better accessibility
/// - More prominent user feedback

class AdaptiveAlertExamples {
  /// Example 1: Basic Success Message
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text("Profile updated successfully"),
  ///     backgroundColor: Colors.green,
  ///   ),
  /// );
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showSuccessExample() {
    AppUtils.showSuccessDialog("Profile updated successfully");
  }

  /// Example 2: Error Message with Custom Title
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text("Failed to connect to server"),
  ///     backgroundColor: Colors.red,
  ///   ),
  /// );
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showErrorExample() {
    AppUtils.showErrorDialog(
      "Failed to connect to server",
      title: "Connection Error",
    );
  }

  /// Example 3: Warning Message
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text("Please check your internet connection"),
  ///     backgroundColor: Colors.orange,
  ///   ),
  /// );
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showWarningExample() {
    AppUtils.showWarningDialog("Please check your internet connection");
  }

  /// Example 4: Information Message
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text("Your data has been synced"),
  ///     backgroundColor: Colors.blue,
  ///   ),
  /// );
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showInfoExample() {
    AppUtils.showInfoDialog("Your data has been synced");
  }

  /// Example 5: Confirmation Dialog
  ///
  /// OLD (SnackBar - limited functionality):
  /// ```dart
  /// // SnackBars can't handle confirmations well
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text("Are you sure?"),
  ///     action: SnackBarAction(
  ///       label: 'Yes',
  ///       onPressed: () => // handle action
  ///     ),
  ///   ),
  /// );
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showConfirmationExample() {
    AppUtils.showConfirmationDialog(
      message: "Are you sure you want to delete this item?",
      title: "Confirm Delete",
      confirmText: "Delete",
      cancelText: "Cancel",
      onConfirm: () {
        // Handle confirmation
        print("Item deleted");
      },
      onCancel: () {
        // Handle cancellation
        print("Delete cancelled");
      },
    );
  }

  /// Example 6: Success Message without Buttons (Auto-dismiss)
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showSuccessNoButtonExample() {
    AppUtils.showSuccessNoButton("Operation completed successfully");
  }

  /// Example 7: API Error Handling
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// try {
  ///   final response = await apiCall();
  ///   if (response.statusCode == 200) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(
  ///         content: Text("Success"),
  ///         backgroundColor: Colors.green,
  ///       ),
  ///     );
  ///   } else {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(
  ///         content: Text("Error: ${response.data}"),
  ///         backgroundColor: Colors.red,
  ///       ),
  ///     );
  ///   }
  /// } catch (e) {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(
  ///       content: Text("Network error"),
  ///       backgroundColor: Colors.red,
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static Future<void> handleApiCall() async {
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Simulate success
      AppUtils.showSuccessDialog("Data saved successfully");

      // Simulate error
      // AppUtils.showErrorDialog("Failed to save data");
    } catch (e) {
      AppUtils.showErrorDialog("Network error occurred");
    }
  }

  /// Example 8: Form Validation Errors
  ///
  /// OLD (SnackBar):
  /// ```dart
  /// if (email.isEmpty) {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(
  ///       content: Text("Email is required"),
  ///       backgroundColor: Colors.red,
  ///     ),
  ///   );
  ///   return;
  /// }
  /// ```
  ///
  /// NEW (Adaptive Alert Dialog):
  static void validateForm(String email, String password) {
    if (email.isEmpty) {
      AppUtils.showErrorDialog("Email is required");
      return;
    }

    if (password.isEmpty) {
      AppUtils.showErrorDialog("Password is required");
      return;
    }

    if (password.length < 6) {
      AppUtils.showWarningDialog("Password must be at least 6 characters");
      return;
    }

    AppUtils.showSuccessDialog("Form is valid");
  }

  /// Example 9: Network Status Messages
  ///
  /// NEW (Adaptive Alert Dialog):
  static void showNetworkStatus() {
    // Check network status
    bool isConnected = true; // Replace with actual network check

    if (isConnected) {
      AppUtils.showInfoDialog("Connected to the internet");
    } else {
      AppUtils.showWarningDialog("No internet connection");
    }
  }

  /// Example 10: User Action Confirmations
  ///
  /// NEW (Adaptive Alert Dialog):
  static void confirmUserAction(String action) {
    AppUtils.showConfirmationDialog(
      message: "Are you sure you want to $action?",
      title: "Confirm Action",
      confirmText: "Yes, proceed",
      cancelText: "Cancel",
      onConfirm: () {
        // Execute the action
        AppUtils.showSuccessDialog("$action completed successfully");
      },
    );
  }
}

/// Migration Guide: Converting SnackBars to Adaptive Alert Dialogs
///
/// 1. Success Messages:
///    OLD: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Success"), backgroundColor: Colors.green))
///    NEW: AppUtils.showSuccessDialog("Success")
///
/// 2. Error Messages:
///    OLD: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error"), backgroundColor: Colors.red))
///    NEW: AppUtils.showErrorDialog("Error")
///
/// 3. Warning Messages:
///    OLD: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Warning"), backgroundColor: Colors.orange))
///    NEW: AppUtils.showWarningDialog("Warning")
///
/// 4. Info Messages:
///    OLD: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Info"), backgroundColor: Colors.blue))
///    NEW: AppUtils.showInfoDialog("Info")
///
/// 5. Confirmations:
///    OLD: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Confirm?"), action: SnackBarAction(...)))
///    NEW: AppUtils.showConfirmationDialog(message: "Confirm?", onConfirm: () => ...)
///
/// Benefits of Adaptive Alert Dialogs:
/// - Better visual hierarchy with icons and titles
/// - Automatic dismissal with configurable timeouts
/// - Consistent styling across the app
/// - Better accessibility
/// - More prominent user feedback
/// - No need to pass BuildContext in most cases
/// - Centralized styling and behavior
