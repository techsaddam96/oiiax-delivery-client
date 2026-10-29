import 'dart:async';

import 'package:blockatie/constants/oiiax_brand.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';
import 'package:blockatie/views/widgets/bottom_nav.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The first Flutter-controlled frame. The supplied merchant artwork belongs
/// here, after the intentionally simple Android/iOS native launch screen.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    final stopwatch = Stopwatch()..start();
    ClientSession session;
    try {
      session = await AuthService.restoreSession();
    } catch (_) {
      session = const ClientSession(clientId: null, apiKey: null);
    }

    if (!mounted || _didNavigate) return;
    _didNavigate = true;

    if (kDebugMode) {
      debugPrint(
        'Splash session check completed in ${stopwatch.elapsedMilliseconds}ms. '
        'Target: ${session.isValid ? 'home' : 'welcome'}',
      );
    }

    if (session.isValid) {
      unawaited(
        FirebaseService.syncClientMessagingSetup(
          clientId: session.clientId,
          apiKey: session.apiKey,
        ),
      );
      Nav.offAll(const CustomBottomNavBar(), withNav: true, navIndex: 0);
      return;
    }

    Nav.offAll(const ClientWelcomePage());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: OIIAXBrand.charcoal,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: const Scaffold(
        backgroundColor: OIIAXBrand.charcoal,
        body: _MerchantSplashArtwork(),
      ),
    );
  }
}

class _MerchantSplashArtwork extends StatelessWidget {
  const _MerchantSplashArtwork();

  static const _sourceAspectRatio = 864 / 1821;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve the storefront, dashboard and delivery rider on wider
        // formats rather than enlarging the image into a destructive crop.
        final screenAspectRatio = constraints.maxWidth / constraints.maxHeight;
        final fit = screenAspectRatio > _sourceAspectRatio * 1.18
            ? BoxFit.contain
            : BoxFit.cover;

        return ColoredBox(
          color: OIIAXBrand.charcoal,
          child: Image.asset(
            OIIAXBrand.merchantSplash,
            key: const Key('oiiax-merchant-splash-artwork'),
            fit: fit,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
            // The supplied artwork already contains the merchant brand, so
            // no duplicate OIIAX logo is overlaid here.
            semanticLabel: 'OIIAX merchant delivery dashboard and storefront',
          ),
        );
      },
    );
  }
}
