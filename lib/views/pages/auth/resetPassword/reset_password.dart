import 'package:blockatie/provider/password_reset.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/password_policy.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/auth/components/auth_flow_widgets.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.identifier,
    required this.code,
  });

  final String identifier;
  final String code;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _isArabic => AppLocalizations.isArabic;

  String get _title =>
      _isArabic ? 'تعيين كلمة مرور جديدة' : 'Create a new password';

  String get _subtitle => _isArabic
      ? 'اختر كلمة مرور قوية لاستخدامها في تسجيل الدخول القادم.'
      : 'Choose a strong password for your next sign-in.';

  String get _sectionTitle =>
      _isArabic ? 'كلمة المرور الجديدة' : 'New password';

  String get _sectionSubtitle => _isArabic
      ? 'استخدم 10 أحرف على الأقل مع حرف كبير وحرف صغير ورقم واحد.'
      : 'Use at least 10 characters with one uppercase letter, one lowercase letter, and one number.';

  String get _passwordLabel =>
      _isArabic ? 'كلمة المرور الجديدة' : 'New password';

  String get _confirmPasswordLabel =>
      _isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';

  String get _buttonLabel => _isArabic ? 'حفظ كلمة المرور' : 'Save password';

  String get _successTitle =>
      _isArabic ? 'تم تحديث كلمة المرور' : 'Password updated';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return AppTranslations.getText('password_required');
    }
    // Password Security V2: the same rules the server enforces.
    return PasswordPolicy.message(password, isArabic: _isArabic);
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return _isArabic
          ? 'يرجى تأكيد كلمة المرور'
          : 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return AppTranslations.getText('passwords_dont_match');
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<PasswordResetProvider>();
    final result = await provider.resetPassword(
      identifier: widget.identifier,
      code: widget.code,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
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

    _passwordController.clear();
    _confirmPasswordController.clear();

    await CustomAlert.showSuccess(
      context: context,
      title: _successTitle,
      content: result.message,
      buttonText: AppTranslations.getText('sign_in'),
    );
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
                  controller: _passwordController,
                  hintText: _passwordLabel,
                  icon: Icons.lock_rounded,
                  validator: _validatePassword,
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _confirmPasswordController,
                  hintText: _confirmPasswordLabel,
                  icon: Icons.lock_outline_rounded,
                  validator: _validateConfirmPassword,
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label: _buttonLabel,
                  isLoading: provider.isResetting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          footer: Text(
            _isArabic
                ? 'بعد الحفظ، استخدم كلمة المرور الجديدة لتسجيل الدخول.'
                : 'After saving, use your new password to sign in.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF74829A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
