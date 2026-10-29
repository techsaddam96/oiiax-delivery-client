import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class DriverRatingButton extends StatelessWidget {
  const DriverRatingButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2.1),
              )
            : const Icon(Icons.star_outline_rounded, size: 18),
        label: Text(
          isRtl ? 'قيّم السائق' : 'Rate Driver',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: const Color(0xffEEF5FF),
          side: const BorderSide(color: Color(0xffD8E8FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
