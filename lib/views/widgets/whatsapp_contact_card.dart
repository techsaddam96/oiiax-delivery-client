import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappContactCard extends StatelessWidget {
  const WhatsappContactCard({
    super.key,
    required this.textTheme,
    this.inSupportBottomSheet = false,
  });

  final TextTheme textTheme;
  final bool inSupportBottomSheet;

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemSettingsProvider>(
      builder: (context, settingsProvider, child) {
        return GestureDetector(
          onTap: () async {
            if (settingsProvider.hasWhatsApp) {
              try {
                // Try WhatsApp app first
                final appUrl = settingsProvider.getWhatsAppUrlWithFallback(
                  message: AppTranslations.getText('whatsapp_message'),
                );

                if (await canLaunchUrl(Uri.parse(appUrl))) {
                  await launchUrl(Uri.parse(appUrl));
                } else {
                  // Fallback to web version
                  final webUrl = settingsProvider.getWhatsAppUrl(
                    message: AppTranslations.getText('whatsapp_message'),
                  );
                  if (await canLaunchUrl(Uri.parse(webUrl))) {
                    await launchUrl(Uri.parse(webUrl));
                  } else {
                    // Show snackbar if neither works
                    if (context.mounted) {
                      AppUtils.showErrorDialog(
                          'Unable to open WhatsApp. Please install WhatsApp or try again.');
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              // color: AppColors.primary,
              border: inSupportBottomSheet
                  ? Border.all(
                      color: AppColors.white,
                    )
                  : null,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: Image.asset(
                    'assets/images/logos_whatsapp-icon.png',
                    height: 20,
                    width: 20,
                  ),
                ),
                Spacing.x(3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getText('whatsapp'),
                        // style: textTheme.bodyLarge!.copyWith(
                        //     fontWeight: FontWeight.w600, color: Colors.white),
                        style: textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        settingsProvider.hasWhatsApp
                            ? AppTranslations.getText('whatsapp_chat_with_us')
                            : AppTranslations.getText('whatsapp_not_available'),
                        style:
                            textTheme.bodyMedium!.copyWith(color: Colors.white),
                      )
                    ],
                  ),
                ),
                if (settingsProvider.hasWhatsApp)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
