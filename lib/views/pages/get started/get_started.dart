import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/extensions/context_extensions.dart';
import 'package:blockatie/extensions/num_extensions.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/dialoges/location_permission.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/widgets/custom_elevated_btn.dart';
// Add this import
import 'package:flutter/material.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  Future<void> _handleLocationPermission(BuildContext context) async {
    final locationService = LocationService();

    // Handle initial location permission
    bool isLocationEnabled =
        await locationService.handleLocationPermission(context);

    if (isLocationEnabled) {
      await AuthService.setClientOnboardingSeen(true);
      // Navigate to login page
      Nav.off(const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradient1, AppColors.gradient2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  (6 * context.widthMultiplier).ph,
                  Image.asset(
                    AppImages.logoSmall,
                    width: 250,
                  ),
                  (8 * context.widthMultiplier).ph,
                  Text(
                    AppTranslations.getText('always_in_control'),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    AppTranslations.getText('always_on_time'),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  (2 * context.widthMultiplier).ph,
                  Text(
                    textAlign: TextAlign.center,
                    AppTranslations.getText('get_started_description'),
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  (4 * context.widthMultiplier).ph,
                  CustomElevatedBtn(
                    label: AppTranslations.getText('get_started'),
                    bgColor: Colors.white,
                    textColor: AppColors.gradient2,
                    onTap: () => _handleLocationPermission(context),
                    width: 64 * context.widthMultiplier,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
