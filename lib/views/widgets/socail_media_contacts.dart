import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SocailMediaContactCard extends StatelessWidget {
  const SocailMediaContactCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen size
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    // Responsive dimensions
    final containerWidth = isSmallScreen
        ? screenWidth * 0.95
        : isMediumScreen
            ? screenWidth * 0.9
            : screenWidth * 0.85;
    final iconSize = isSmallScreen
        ? 20.0
        : isMediumScreen
            ? 24.0
            : 28.0;
    final horizontalPadding = isSmallScreen
        ? 16.0
        : isMediumScreen
            ? 20.0
            : 24.0;
    final verticalPadding = isSmallScreen
        ? 12.0
        : isMediumScreen
            ? 16.0
            : 20.0;

    return Consumer<SystemSettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Center(
          child: SizedBox(
            width: containerWidth,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (settingsProvider.hasFacebook)
                    GestureDetector(
                      onTap: () async {
                        try {
                          final url = settingsProvider.facebookUrl;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppUtils.showErrorDialog(
                                'Error opening Facebook: ${e.toString()}');
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(horizontalPadding * 0.5),
                        child: Image.asset(
                          'assets/images/facebook.png',
                          width: iconSize,
                          height: iconSize,
                        ),
                      ),
                    ),
                  if (settingsProvider.hasInstagram)
                    GestureDetector(
                      onTap: () async {
                        try {
                          final url = settingsProvider.instagramUrl;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppUtils.showErrorDialog(
                                'Error opening Instagram: ${e.toString()}');
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(horizontalPadding * 0.5),
                        child: Image.asset(
                          'assets/images/instagram.png',
                          width: iconSize,
                          height: iconSize,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
