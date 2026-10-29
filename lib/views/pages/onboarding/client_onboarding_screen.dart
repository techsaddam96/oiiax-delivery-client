import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _imageOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentOpacity;

  bool _isContinuing = false;

  bool get _isArabic => AppLocalizations.isArabic;

  String get _title =>
      _isArabic ? 'توصيل أسرع، إدارة أذكى' : 'Faster delivery, smarter control';

  String get _description => _isArabic
      ? 'تابع شحناتك، اطلب توصيل فوري، واعرف حالة طلبك لحظة بلحظة من مكان واحد.'
      : 'Track shipments, request instant delivery, and monitor every order from one place.';

  String get _buttonLabel => _isArabic ? 'ابدأ الآن' : 'Start now';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _imageOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.18, 1, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isContinuing) {
      return;
    }

    setState(() => _isContinuing = true);
    try {
      await AuthService.setClientOnboardingSeen(true);
      if (!mounted) {
        return;
      }
      Nav.offAll(const LoginPage());
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 360 ? 20.0 : 26.0;
              final compactHeight = constraints.maxHeight < 670;
              final titleSize = constraints.maxWidth < 360 ? 28.0 : 32.0;
              final buttonHeight = constraints.maxWidth < 360 ? 54.0 : 58.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  FadeTransition(
                    opacity: _imageOpacity,
                    child: _OnboardingBackground(isArabic: _isArabic),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.68),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0, 0.42, 0.74, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentOpacity,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SingleChildScrollView(
                            physics: compactHeight
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              28,
                              horizontalPadding,
                              22,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 44,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _DecorativeDots(),
                                  const SizedBox(height: 18),
                                  Text(
                                    _title,
                                    textAlign: TextAlign.start,
                                    style: textTheme.headlineLarge?.copyWith(
                                          color: Colors.white,
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          height: 1.18,
                                        ) ??
                                        TextStyle(
                                          color: Colors.white,
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          height: 1.18,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 420,
                                    ),
                                    child: Text(
                                      _description,
                                      textAlign: TextAlign.start,
                                      style: textTheme.bodyLarge?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            height: 1.7,
                                            fontWeight: FontWeight.w500,
                                          ) ??
                                          TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            height: 1.7,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 24 : 32),
                                  Semantics(
                                    button: true,
                                    label: _buttonLabel,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: _isContinuing
                                            ? null
                                            : _handleContinue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          disabledBackgroundColor:
                                              AppColors.primary.withValues(
                                            alpha: 0.72,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                          ),
                                        ),
                                        child: _OnboardingButtonContent(
                                          isArabic: _isArabic,
                                          isLoading: _isContinuing,
                                          label: _buttonLabel,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppImages.clientOnboarding,
          fit: BoxFit.cover,
          alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
          errorBuilder: (_, __, ___) => const _OnboardingFallbackBackground(),
        ),
        const _OnboardingAmbientOverlay(),
      ],
    );
  }
}

class _OnboardingFallbackBackground extends StatelessWidget {
  const _OnboardingFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradient2,
            const Color(0xFF073B7A),
            AppColors.primary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _GlowCircle(
              size: 220,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 120,
            child: _GlowCircle(
              size: 180,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 44,
                      ),
                      SizedBox(height: 14),
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white70,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAmbientOverlay extends StatelessWidget {
  const _OnboardingAmbientOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
            child: _GlowCircle(
              size: 230,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -40,
            child: _GlowCircle(
              size: 180,
              color: AppColors.secondary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _DecorativeDots extends StatelessWidget {
  const _DecorativeDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Container(
          width: index == 1 ? 26 : 8,
          height: 8,
          margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 6),
          decoration: BoxDecoration(
            color: index == 1
                ? Colors.white
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingButtonContent extends StatelessWidget {
  const _OnboardingButtonContent({
    required this.isArabic,
    required this.isLoading,
    required this.label,
  });

  final bool isArabic;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        );

    return Row(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Icon(
          isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
          size: 20,
        ),
        const Spacer(),
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}
