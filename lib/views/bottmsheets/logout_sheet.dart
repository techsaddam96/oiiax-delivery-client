import 'dart:ui';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';
import 'package:flutter/material.dart';

class LogoutBottomSheet extends StatefulWidget {
  const LogoutBottomSheet({super.key});

  @override
  State<LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends State<LogoutBottomSheet> {
  bool _isLoggingOut = false;

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
    } finally {
      Nav.offAll(const ClientWelcomePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Apply blur effect
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
              alpha: 0.8), // Semi-transparent white for frosted effect
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: SizeConfig.widthMultiplier * 13,
              height: 2,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Semantics(
                label: AppTranslations.getText('logout'),
                header: true,
                child: Text(
                  AppTranslations.getText('logout'),
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Text(
              AppTranslations.getText('logout_confirmation'),
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
              textAlign:
                  AppLocalizations.isRTL ? TextAlign.right : TextAlign.center,
              semanticsLabel: AppTranslations.getText('logout_confirmation'),
            ),
            Spacing.y(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  child: Semantics(
                    label: AppTranslations.getText('cancel'),
                    button: true,
                    child: Container(
                      height: SizeConfig.heightMultiplier * 5,
                      width: SizeConfig.widthMultiplier * 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Center(
                        child: Text(
                          AppTranslations.getText('cancel'),
                          style: textTheme.bodyMedium!
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacing.x(5),
                InkWell(
                  onTap: _isLoggingOut ? null : _confirmLogout,
                  child: Semantics(
                    label: AppTranslations.getText('yes_logout'),
                    button: true,
                    child: Container(
                      height: SizeConfig.heightMultiplier * 5,
                      width: SizeConfig.widthMultiplier * 35,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          AppTranslations.getText('yes_logout'),
                          style: textTheme.bodyMedium!
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Spacing.y(4),
          ],
        ),
      ),
    );
  }
}
