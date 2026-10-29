import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';

class CustomAlertExamples {
  // Example 1: Single button alert (like the wallet withdrawal alert)
  static void showWithdrawalAlert(BuildContext context) {
    CustomAlert.show(
      context: context,
      title: AppTranslations.getText('withdrawal_alert'),
      content: AppTranslations.getText('withdrawal_alert_desc'),
      type: AlertType.warning,
      buttonType: AlertButtonType.single,
      primaryButtonText: AppTranslations.getText('ok'),
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Handle withdrawal logic here
      },
    );
  }

  // Example 2: Dual button confirmation (like shipment acceptance)
  static void showShipmentAcceptanceConfirmation(BuildContext context) {
    CustomAlert.showConfirmation(
      context: context,
      title: AppTranslations.getText('confirmation_of_acceptance'),
      content: AppTranslations.getText('do_you_want_to_deliver_this_shipment'),
      primaryButtonText: AppTranslations.getText('yes_accept'),
      secondaryButtonText: AppTranslations.getText('cancel'),
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Handle acceptance logic here
        showShipmentAccepted(context);
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Example 3: Success message with no buttons (auto-dismiss)
  static void showShipmentAccepted(BuildContext context) {
    CustomAlert.showSuccessNoButton(
      context: context,
      title: AppTranslations.getText('shipment_accepted'),
      content: AppTranslations.getText('shipment_accepted_successfully'),
      onDismiss: () {
        Navigator.of(context).pop();
        // Auto-dismiss after 2 seconds or handle tap outside
      },
    );
  }

  // Example 4: Receipt confirmation
  static void showReceiptConfirmation(BuildContext context) {
    CustomAlert.showConfirmation(
      context: context,
      title: AppTranslations.getText('confirmation_receipt'),
      content:
          AppTranslations.getText('are_you_sure_you_want_receipt_shipment'),
      primaryButtonText: AppTranslations.getText('yes_accept'),
      secondaryButtonText: AppTranslations.getText('cancel'),
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Handle receipt logic here
        showReceiptSuccess(context);
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Example 5: Receipt success
  static void showReceiptSuccess(BuildContext context) {
    CustomAlert.showSuccessNoButton(
      context: context,
      title: AppTranslations.getText('shipment_receipt'),
      content: AppTranslations.getText(
          'the_shipment_has_been_received_successfully'),
      onDismiss: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Example 6: Error alert
  static void showErrorAlert(BuildContext context, String errorMessage) {
    CustomAlert.showError(
      context: context,
      title: AppTranslations.getText('error'),
      content: errorMessage,
      buttonText: AppTranslations.getText('ok'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Example 7: Info alert
  static void showInfoAlert(
      BuildContext context, String title, String message) {
    CustomAlert.showInfo(
      context: context,
      title: title,
      content: message,
      buttonText: AppTranslations.getText('got_it'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Example 8: Custom alert with different button text
  static void showCustomAlert(BuildContext context) {
    CustomAlert.show(
      context: context,
      title: AppTranslations.getText('custom_alert'),
      content: AppTranslations.getText('custom_alert_desc'),
      type: AlertType.info,
      buttonType: AlertButtonType.dual,
      primaryButtonText: "Proceed",
      secondaryButtonText: "Go Back",
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Handle proceed logic
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
        // Handle go back logic
      },
    );
  }

  // Example 9: Non-dismissible alert
  static void showNonDismissibleAlert(BuildContext context) {
    CustomAlert.show(
      context: context,
      title: "Important Notice",
      content: "This alert cannot be dismissed by tapping outside",
      type: AlertType.warning,
      buttonType: AlertButtonType.single,
      primaryButtonText: "I Understand",
      barrierDismissible: false,
      onPrimaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}

// Usage examples in your widgets:
/*
// In a button onPressed:
ElevatedButton(
  onPressed: () {
    CustomAlertExamples.showWithdrawalAlert(context);
  },
  child: Text('Show Withdrawal Alert'),
),

// Or use the direct methods:
ElevatedButton(
  onPressed: () {
    CustomAlert.showSuccess(
      context: context,
      title: "Success!",
      content: "Operation completed successfully",
    );
  },
  child: Text('Show Success'),
),

// For confirmation dialogs:
ElevatedButton(
  onPressed: () {
    CustomAlert.showConfirmation(
      context: context,
      title: "Delete Item",
      content: "Are you sure you want to delete this item?",
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Delete the item
      },
    );
  },
  child: Text('Delete Item'),
),
*/
