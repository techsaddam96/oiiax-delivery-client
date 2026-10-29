import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/email_verification.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/auth/components/auth_flow_widgets.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({
    super.key,
    required this.identifier,
  });

  final String identifier;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmailVerificationProvider(),
      child: _VerifyEmailView(identifier: identifier),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({required this.identifier});

  final String identifier;

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool get _isArabic => AppLocalizations.isArabic;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<EmailVerificationProvider>();
    final result = await provider.verify(
      identifier: widget.identifier,
      code: _codeController.text,
    );
    if (!mounted) {
      return;
    }

    if (!result.success) {
      await CustomAlert.showError(
        context: context,
        title: _isArabic ? 'تعذر التحقق' : 'Verification failed',
        content: result.message,
        buttonText: _isArabic ? 'حسناً' : 'OK',
      );
      return;
    }

    _codeController.clear();
    await CustomAlert.showSuccess(
      context: context,
      title: _isArabic ? 'تم تفعيل الحساب' : 'Account activated',
      content: result.message,
      buttonText: _isArabic ? 'تسجيل الدخول' : 'Sign in',
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _resend() async {
    final provider = context.read<EmailVerificationProvider>();
    final result = await provider.resend(widget.identifier);
    if (!mounted) {
      return;
    }
    if (result.success) {
      await CustomAlert.showInfo(
        context: context,
        title: _isArabic ? 'تم طلب رمز جديد' : 'New code requested',
        content: result.message,
        buttonText: _isArabic ? 'حسناً' : 'OK',
      );
    } else {
      await CustomAlert.showError(
        context: context,
        title: _isArabic ? 'تعذر الإرسال' : 'Unable to resend',
        content: result.message,
        buttonText: _isArabic ? 'حسناً' : 'OK',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailVerificationProvider>(
      builder: (context, provider, _) {
        return AuthFlowScaffold(
          title: _isArabic ? 'تأكيد البريد الإلكتروني' : 'Verify your email',
          subtitle: _isArabic
              ? 'أدخل الرمز المكوّن من 6 أرقام لتفعيل حساب متجرك.'
              : 'Enter the 6-digit code to activate your store account.',
          headerAction: AuthHeaderAction(
            label: _isArabic ? 'رجوع' : 'Back',
            icon: _isArabic
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded,
            onTap: _handleBack,
          ),
          cardChild: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isArabic ? 'رمز التفعيل' : 'Activation code',
                  style: const TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isArabic
                      ? 'تحقق من بريدك الإلكتروني. تنتهي صلاحية الرمز خلال 45 دقيقة.'
                      : 'Check your email. The code expires in 45 minutes.',
                  style: const TextStyle(
                    color: Color(0xFF74829A),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _verify(),
                  validator: (value) => (value ?? '').length == 6
                      ? null
                      : (_isArabic
                          ? 'أدخل رمزاً صحيحاً من 6 أرقام'
                          : 'Enter a valid 6-digit code'),
                  style: const TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF6F9FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label:
                      _isArabic ? 'تأكيد وتفعيل الحساب' : 'Verify and activate',
                  isLoading: provider.isVerifying,
                  onPressed: _verify,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: provider.canResend ? _resend : null,
                  child: Text(
                    provider.canResend
                        ? (_isArabic ? 'إعادة إرسال الرمز' : 'Resend code')
                        : (_isArabic
                            ? 'إعادة الإرسال خلال ${provider.resendSeconds}ث'
                            : 'Resend in ${provider.resendSeconds}s'),
                    style: TextStyle(
                      color: provider.canResend
                          ? AppColors.primary
                          : const Color(0xFF8A97AA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
