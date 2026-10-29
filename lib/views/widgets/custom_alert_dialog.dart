import 'package:flutter/material.dart';
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/spacing.dart';

enum AlertType {
  success,
  warning,
  error,
  info,
}

enum AlertButtonType {
  none,
  single,
  dual,
}

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final AlertType type;
  final AlertButtonType buttonType;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onDismiss;
  final bool barrierDismissible;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.type = AlertType.info,
    this.buttonType = AlertButtonType.single,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.onDismiss,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: barrierDismissible ? onDismiss : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              _buildIcon(),
              Spacing.y(2),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                textAlign: TextAlign.center,
              ),
              Spacing.y(1.5),

              // Content
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              Spacing.y(3),

              // Buttons
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;
    double iconSize = 60;

    switch (type) {
      case AlertType.success:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case AlertType.warning:
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case AlertType.error:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case AlertType.info:
        iconData = Icons.info;
        iconColor = AppColors.primary;
        break;
    }

    return Icon(
      iconData,
      size: iconSize,
      color: iconColor,
    );
  }

  Widget _buildButtons() {
    switch (buttonType) {
      case AlertButtonType.none:
        return const SizedBox.shrink();

      case AlertButtonType.single:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPrimaryPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              primaryButtonText ?? 'OK',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case AlertButtonType.dual:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onSecondaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  secondaryButtonText ?? 'Cancel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  primaryButtonText ?? 'Confirm',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

// Helper class to show dialogs easily
class CustomAlert {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    AlertType type = AlertType.info,
    AlertButtonType buttonType = AlertButtonType.single,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    VoidCallback? onDismiss,
    bool barrierDismissible = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomAlertDialog(
        title: title,
        content: content,
        type: type,
        buttonType: buttonType,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
        onSecondaryPressed:
            onSecondaryPressed ?? () => Navigator.of(context).pop(),
        onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  // Convenience methods for common scenarios
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.success,
      buttonType: AlertButtonType.single,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed,
    );
  }

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String content,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.warning,
      buttonType: AlertButtonType.dual,
      primaryButtonText: primaryButtonText ?? 'Yes',
      secondaryButtonText: secondaryButtonText ?? 'Cancel',
      onPrimaryPressed: onPrimaryPressed,
      onSecondaryPressed: onSecondaryPressed,
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.error,
      buttonType: AlertButtonType.single,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed,
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.info,
      buttonType: AlertButtonType.single,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed,
    );
  }

  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.warning,
      buttonType: AlertButtonType.dual,
      primaryButtonText: primaryButtonText ?? 'Yes',
      secondaryButtonText: secondaryButtonText ?? 'Cancel',
      onPrimaryPressed: onPrimaryPressed,
      onSecondaryPressed: onSecondaryPressed,
    );
  }

  static Future<void> showSuccessNoButton({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      type: AlertType.success,
      buttonType: AlertButtonType.none,
      onDismiss: onDismiss,
    );
  }
}
