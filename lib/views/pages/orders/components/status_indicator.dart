import 'package:blockatie/constants/colors.dart';
import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final double? containersize;
  final bool showLabel;
  final double? iconsize;
  final double? radius;
  final Color? iconColor;
  final Color? continercolor;
  final VoidCallback? onTap;

  const StatusIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.containersize,
    this.showLabel = true,
    this.iconsize,
    this.radius,
    this.iconColor,
    this.continercolor,
    this.onTap,
  });

  Color? _getActiveStatusColor(String label, bool isActive) {
    if (!isActive) return null;

    final lower = label.toLowerCase();

    if (lower == 'cancelled' ||
        lower == 'returned' ||
        lower == 'failed delivery') {
      return Colors.red[600];
    }

    if (lower == 'delivered' || lower == 'completed') {
      return Colors.green[600];
    }

    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final showGradientBorder =
        !isActive; // Only active status gets primary color

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: containersize ?? 38,
            height: containersize ?? 38,
            decoration: showGradientBorder
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradient1, AppColors.gradient2],
                    ),
                    borderRadius: BorderRadius.circular(radius ?? 12))
                : null,
            child: Container(
              width: (containersize ?? 37) - 1,
              height: (containersize ?? 37) - 1,
              margin: showGradientBorder
                  ? EdgeInsets.all(showLabel ? 0.3 : 0.5)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: _getActiveStatusColor(label, isActive) ??
                    continercolor ??
                    Colors.white,
                borderRadius: BorderRadius.circular(radius ?? 12),
                border: showGradientBorder
                    ? null
                    : Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  color:
                      isActive ? Colors.white : iconColor ?? Colors.grey[600],
                  width: iconsize ?? 20,
                  height: iconsize ?? 20,
                ),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? _getActiveStatusColor(label, isActive) ??
                        AppColors.primary
                    : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
