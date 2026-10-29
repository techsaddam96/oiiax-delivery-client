import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/password_reset.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/auth/components/auth_flow_widgets.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/pages/auth/verifyOtp/verify_otp.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ForgetPasswordPage extends StatelessWidget {
  const ForgetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PasswordResetProvider(),
      child: const _ForgetPasswordView(),
    );
  }
}

class _ForgetPasswordView extends StatefulWidget {
  const _ForgetPasswordView();

  @override
  State<_ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<_ForgetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  bool get _isArabic => AppLocalizations.isArabic;

  String get _title => _isArabic ? 'استعادة كلمة المرور' : 'Forgot password';

  String get _subtitle => _isArabic
      ? 'أدخل بريدك الإلكتروني المسجل، وسنرسل تعليمات إعادة التعيين إذا كان مرتبطاً بحساب.'
      : 'Enter your registered email and we will send reset instructions if it is associated with an account.';

  String get _sectionTitle =>
      _isArabic ? 'أدخل معلومات الحساب' : 'Enter your account details';

  String get _sectionSubtitle => _isArabic
      ? 'سنرسل رمز تحقق صالحاً لفترة قصيرة إذا كان البريد مرتبطاً بحساب.'
      : 'We will send a short-lived verification code if the email is associated with an account.';

  String get _fieldLabel => _isArabic ? 'البريد الإلكتروني' : 'Email address';

  String get _buttonLabel =>
      _isArabic ? 'إرسال رمز التحقق' : 'Send verification code';

  String get _successTitle =>
      _isArabic ? 'تم إرسال التعليمات' : 'Instructions sent';

  String get _genericSuccess => _isArabic
      ? 'إذا كان البريد الإلكتروني مرتبطاً بحساب، فسيتم إرسال تعليمات إعادة تعيين كلمة المرور.'
      : 'If the email is associated with an account, password reset instructions will be sent.';

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<PasswordResetProvider>();
    final result = await provider.sendCode(_identifierController.text);
    if (!mounted) {
      return;
    }

    if (!result.success) {
      await CustomAlert.showError(
        context: context,
        title: AppTranslations.getText('error'),
        content: result.message,
        buttonText: AppTranslations.getText('ok'),
      );
      return;
    }

    await CustomAlert.showSuccess(
      context: context,
      title: _successTitle,
      content: _genericSuccess,
      buttonText: AppTranslations.getText('continue'),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: VerifyOtpPage(
            identifier: _identifierController.text.trim(),
          ),
        ),
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return _isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email address';
    }

    const emailPattern = r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$";
    final isEmail = RegExp(emailPattern, caseSensitive: false).hasMatch(text);
    if (!isEmail) {
      return _isArabic
          ? 'أدخل بريداً إلكترونياً صحيحاً'
          : 'Enter a valid email address';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordResetProvider>(
      builder: (context, provider, _) {
        return AuthFlowScaffold(
          title: _title,
          subtitle: _subtitle,
          headerAction: AuthHeaderAction(
            label: AppTranslations.getText('back'),
            icon: _isArabic
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded,
            onTap: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
          cardChild: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _sectionTitle,
                  style: const TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _sectionSubtitle,
                  style: const TextStyle(
                    color: Color(0xFF74829A),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                AuthInputField(
                  controller: _identifierController,
                  hintText: _fieldLabel,
                  icon: Icons.alternate_email_rounded,
                  validator: _validateIdentifier,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onSubmitted: (_) => _submit(context),
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label: _buttonLabel,
                  isLoading: provider.isSending,
                  onPressed: () => _submit(context),
                ),
              ],
            ),
          ),
          footer: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                AppTranslations.getText('remember_password'),
                style: const TextStyle(
                  color: Color(0xFF74829A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: Text(
                  AppTranslations.getText('sign_in'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
