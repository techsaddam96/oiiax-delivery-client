import 'dart:math' as math;
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/user_session_state.dart';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/constants/oiiax_brand.dart';
import 'package:blockatie/provider/login.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/bottmsheets/support_sheet.dart';
import 'package:blockatie/views/pages/auth/forget/forgetPassword.dart';
import 'package:blockatie/views/pages/auth/login/components/custom_checkbox.dart';
import 'package:blockatie/views/pages/auth/signup/register.dart';
import 'package:blockatie/views/widgets/bottom_nav.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:blockatie/views/widgets/protected_blockatie_attribution.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isArabic => AppLocalizations.isArabic;

  String get _heading => _isArabic ? 'تسجيل دخول المتجر' : 'Store Login';

  String get _subtitle => _isArabic
      ? 'ادخل إلى لوحة متجرك لإدارة الشحنات والطلبات'
      : 'Access your store dashboard to manage shipments and orders';

  String get _supportLabel => _isArabic ? 'مساعدة؟' : 'Help?';

  String get _phoneHint =>
      _isArabic ? 'البريد الإلكتروني أو رقم الهاتف' : 'Email or phone number';

  String get _passwordHint => _isArabic ? 'كلمة المرور' : 'Password';

  Future<void> _submit(LoginProvider authProvider) async {
    FocusScope.of(context).unfocus();

    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final result = await authProvider.logIn();
    if (!mounted) return;
    if (result.success) {
      final generation = UserSessionState.generation;
      final profile = context.read<ProfileProvider>();
      // No previous account values are used while the new critical data loads.
      await Future.wait([
        profile.fetchClientProfile(silent: true),
        profile.fetchClientStatistics()
      ]);
      if (!mounted ||
          generation != UserSessionState.generation ||
          AuthService.currentSession?.isValid != true) {
        return;
      }
      setState(() => _isSubmitting = false);
      Nav.offAll(const CustomBottomNavBar(), withNav: true, navIndex: 0);
      return;
    }

    setState(() => _isSubmitting = false);
    if (result.code == 'EMAIL_NOT_VERIFIED' ||
        result.code == 'ACCOUNT_PENDING_ACTIVATION') {
      await CustomAlert.showInfo(
        context: context,
        title: _isArabic ? 'البريد غير مؤكد' : 'Email not verified',
        content: result.message,
        buttonText: _isArabic ? 'متابعة التفعيل' : 'Continue verification',
      );
      return;
    }

    await CustomAlert.showError(
      context: context,
      title: _isArabic ? 'تعذر تسجيل الدخول' : 'Sign-in failed',
      content: result.message,
      buttonText: _isArabic ? 'حسناً' : 'OK',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<LoginProvider>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final logoWidth = math.min(size.width * 0.38, 150.0);
    final headerHeight = math.max(size.height * 0.48, 390.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: OIIAXBrand.lightGray,
        body: Stack(
          children: [
            _BackgroundBand(height: headerHeight),
            SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, constraints.maxHeight - 42),
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: _isArabic
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: _HelpButton(
                                label: _supportLabel,
                                onTap: () => SupportBottomSheet.show(context),
                              ),
                            ),
                            const SizedBox(height: 26),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  Image.asset(
                                    AppImages.logo,
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.storefront_rounded,
                                      color: Colors.white,
                                      size: 70,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _heading,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      _subtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.78,
                                        ),
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: math.max(size.height * 0.07, 46.0),
                            ),
                            SlideTransition(
                              position: _cardSlideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _LoginCard(
                                  formKey: _formKey,
                                  phoneHint: _phoneHint,
                                  passwordHint: _passwordHint,
                                  isSubmitting: _isSubmitting,
                                  authProvider: authProvider,
                                  onSubmit: () => _submit(authProvider),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _RegisterLink(isArabic: _isArabic),
                            const SizedBox(height: 18),
                            const ProtectedBlockatieAttribution(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundBand extends StatelessWidget {
  const _BackgroundBand({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradient1,
            AppColors.gradient2,
            AppColors.gradient2,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -56,
            child: _GlowCircle(
              size: 190,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 16,
            left: -80,
            child: _GlowCircle(
              size: 170,
              color: OIIAXBrand.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.phoneHint,
    required this.passwordHint,
    required this.isSubmitting,
    required this.authProvider,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String phoneHint;
  final String passwordHint;
  final bool isSubmitting;
  final LoginProvider authProvider;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5B).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.isArabic ? 'أهلاً بعودتك' : 'Welcome back',
              style: const TextStyle(
                color: Color(0xFF10233F),
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.isArabic
                  ? 'أدخل بيانات المتجر للمتابعة'
                  : 'Enter your store credentials to continue',
              style: const TextStyle(
                color: Color(0xFF74829A),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _AuthInput(
              controller: authProvider.phoneCont,
              hintText: phoneHint,
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final normalized =
                    authProvider.normalizeIdentifier(value ?? '');
                if (normalized.isEmpty) {
                  return AppLocalizations.isArabic
                      ? 'أدخل البريد الإلكتروني أو رقم الهاتف'
                      : 'Enter your email or phone number';
                }
                final isEmail = RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(normalized);
                final isPhone =
                    RegExp(r'^07(7|8|9)\d{7}$').hasMatch(normalized);
                if (!isEmail && !isPhone) {
                  return AppLocalizations.isArabic
                      ? 'أدخل بريداً أو رقم هاتف صحيحاً'
                      : 'Enter a valid email or phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthInput(
              controller: authProvider.passCont,
              hintText: passwordHint,
              icon: Icons.lock_rounded,
              isPassword: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppTranslations.getText('password_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CustomCheckbox(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.getText('remember_me'),
                    style: const TextStyle(
                      color: Color(0xFF6B7890),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Nav.offAll(const ForgetPasswordPage()),
                  child: Text(
                    AppTranslations.getText('forgot_password'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LoginButton(
              isLoading: isSubmitting,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthInput extends StatefulWidget {
  const _AuthInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.isPassword = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;

  @override
  State<_AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<_AuthInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword && _obscureText,
      validator: widget.validator,
      textInputAction:
          widget.isPassword ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(
        color: Color(0xFF10233F),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF6F9FD),
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8390A4),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          widget.icon,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: AppLocalizations.isArabic
                    ? (_obscureText ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور')
                    : (_obscureText ? 'Show password' : 'Hide password'),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF7C8BA0),
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE7F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE55353)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE55353), width: 1.2),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.62),
          foregroundColor: OIIAXBrand.charcoal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      OIIAXBrand.charcoal,
                    ),
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppTranslations.getText('login'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  const _RegisterLink({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          AppTranslations.getText('dont_have_account'),
          style: const TextStyle(
            color: Color(0xFF74829A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () => Nav.offAll(const RegisterPage()),
          child: Text(
            AppTranslations.getText('sign_up'),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
