import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintRowWidget extends StatelessWidget {
  const ComplaintRowWidget({
    super.key,
    required this.textTheme,
    this.inSupportBottomSheet = false,
  });

  final TextTheme textTheme;
  final bool inSupportBottomSheet;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on screen size
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;

    // Responsive font sizes
    final titleFontSize = isSmallScreen
        ? 10.0
        : isMediumScreen
            ? 12.0
            : 14.0;
    final subtitleFontSize = isSmallScreen
        ? 8.0
        : isMediumScreen
            ? 10.0
            : 12.0;
    final iconSize = isSmallScreen
        ? 16.0
        : isMediumScreen
            ? 18.0
            : 20.0;
    final avatarRadius = isSmallScreen
        ? 16.0
        : isMediumScreen
            ? 18.0
            : 20.0;

    // Responsive padding
    final horizontalPadding = isSmallScreen
        ? 8.0
        : isMediumScreen
            ? 12.0
            : 16.0;
    final verticalPadding = isSmallScreen
        ? 8.0
        : isMediumScreen
            ? 10.0
            : 12.0;

    return Consumer<SystemSettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Row(
          children: [
            // First container - WhatsApp Chat
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (settingsProvider.hasWhatsApp) {
                    try {
                      // Try WhatsApp app first
                      final appUrl =
                          settingsProvider.getWhatsAppUrlWithFallback(
                        message:
                            'Hello! I have a complaint or need assistance.',
                      );

                      if (await canLaunchUrl(Uri.parse(appUrl))) {
                        await launchUrl(Uri.parse(appUrl));
                      } else {
                        // Fallback to web version
                        final webUrl = settingsProvider.getWhatsAppUrl(
                          message:
                              'Hello! I have a complaint or need assistance.',
                        );
                        if (await canLaunchUrl(Uri.parse(webUrl))) {
                          await launchUrl(Uri.parse(webUrl));
                        } else {
                          // Show snackbar if neither works
                          if (context.mounted) {
                            AppUtils.showErrorDialog(AppTranslations.getText(
                                'unable_open_whatsapp'));
                          }
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppUtils.showErrorDialog(
                            'Error opening WhatsApp: ${e.toString()}');
                      }
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: inSupportBottomSheet
                        ? Border.all(
                            color: AppColors.white,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: horizontalPadding,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/complaint.png',
                          width: iconSize,
                          height: iconSize,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: horizontalPadding * 0.5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText('chat_with_us'),
                              style: textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              settingsProvider.hasWhatsApp
                                  ? AppTranslations.getText('whatsapp')
                                  : AppTranslations.getText('not_available'),
                              style: textTheme.bodySmall!.copyWith(
                                fontSize: subtitleFontSize,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (settingsProvider.hasWhatsApp)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: iconSize * 0.8,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: horizontalPadding * 0.5),

            // Second container - Phone Contact
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (settingsProvider.hasPhone) {
                    try {
                      final url = settingsProvider.getPhoneCallUrl();
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        if (context.mounted) {
                          AppUtils.showErrorDialog(
                              AppTranslations.getText('unable_make_call'));
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppUtils.showErrorDialog(
                            'Error making phone call: ${e.toString()}');
                      }
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: inSupportBottomSheet
                        ? Border.all(
                            color: AppColors.white,
                          )
                        : null,
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/phone.png',
                          width: iconSize,
                          height: iconSize,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: horizontalPadding * 0.5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText('contact_us'),
                              style: textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              settingsProvider.hasPhone
                                  ? AppTranslations.getText('call_us_now')
                                  : AppTranslations.getText('not_available'),
                              style: textTheme.bodySmall!.copyWith(
                                fontSize: subtitleFontSize,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (settingsProvider.hasPhone)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: iconSize * 0.8,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
