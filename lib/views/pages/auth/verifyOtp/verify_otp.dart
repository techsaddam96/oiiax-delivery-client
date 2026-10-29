import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/password_reset.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/auth/components/auth_flow_widgets.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/pages/auth/resetPassword/reset_password.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.identifier,
  });

  final String identifier;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  static const int _otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool get _isArabic => AppLocalizations.isArabic;

  String get _title => _isArabic ? 'التحقق من الرمز' : 'Verify reset code';

  String get _subtitle => _isArabic
      ? 'أدخل رمز التحقق المكوّن من 6 أرقام لمتابعة إعادة تعيين كلمة المرور.'
      : 'Enter the 6-digit verification code to continue resetting your password.';

  String get _sectionTitle =>
      _isArabic ? 'أدخل الرمز المرسل' : 'Enter the code we sent';

  String get _sectionSubtitle => _isArabic
      ? 'الرمز صالح لفترة قصيرة. يمكنك طلب إعادة الإرسال بعد انتهاء العد التنازلي.'
      : 'The code is valid for a short time. You can request a resend after the countdown ends.';

  String get _verifyLabel => _isArabic ? 'تأكيد الرمز' : 'Verify code';

  String get _resendReadyLabel =>
      _isArabic ? 'إعادة إرسال الرمز' : 'Resend code';

  String get _backLabel => AppTranslations.getText('back');

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      _otpLength,
      (_) => FocusNode(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<PasswordResetProvider>().bindIdentifier(widget.identifier);
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  String get _maskedIdentifier {
    final value = widget.identifier.trim();
    if (value.contains('@')) {
      final parts = value.split('@');
      final local = parts.first;
      final domain = parts.length > 1 ? parts.last : '';
      final visibleLocal = local.length <= 2
          ? local.substring(0, 1)
          : '${local.substring(0, 2)}***';
      return '$visibleLocal@$domain';
    }

    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length <= 4) {
      return digits;
    }
    return '${digits.substring(0, 3)}***${digits.substring(digits.length - 2)}';
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<PasswordResetProvider>();
    final code = _code.trim();

    if (code.length != _otpLength) {
      await CustomAlert.showError(
        context: context,
        title: AppTranslations.getText('error'),
        content: _isArabic
            ? 'أدخل رمز التحقق كاملاً قبل المتابعة'
            : 'Enter the full verification code before continuing.',
        buttonText: AppTranslations.getText('ok'),
      );
      return;
    }

    final result = await provider.verifyCode(
      identifier: widget.identifier,
      code: code,
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ResetPasswordPage(
            identifier: widget.identifier,
            code: code,
          ),
        ),
      ),
    );
  }

  Future<void> _resendCode() async {
    final provider = context.read<PasswordResetProvider>();
    final result = await provider.resendCode();
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

    _clearCode();
    await CustomAlert.showInfo(
      context: context,
      title: _isArabic ? 'تمت إعادة الإرسال' : 'Code resent',
      content: _isArabic
          ? 'إذا كانت البيانات صحيحة، فقد تم إرسال رمز جديد.'
          : 'If the account details are correct, a new code has been sent.',
      buttonText: AppTranslations.getText('ok'),
    );
    if (!mounted) {
      return;
    }
    _focusNodes.first.requestFocus();
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _controllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    if (digits.length > 1) {
      _fillFrom(index, digits);
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index].text.length),
    );

    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  void _fillFrom(int startIndex, String digits) {
    var targetIndex = startIndex;
    for (final digit in digits.split('')) {
      if (targetIndex >= _otpLength) {
        break;
      }
      _controllers[targetIndex].text = digit;
      targetIndex += 1;
    }

    final nextIndex = targetIndex >= _otpLength ? _otpLength - 1 : targetIndex;
    _focusNodes[nextIndex].requestFocus();
  }

  String _resendLabel(PasswordResetProvider provider) {
    if (provider.resendSecondsRemaining <= 0) {
      return _resendReadyLabel;
    }

    if (_isArabic) {
      return 'إعادة الإرسال خلال ${provider.resendSecondsRemaining}ث';
    }
    return 'Resend in ${provider.resendSecondsRemaining}s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordResetProvider>(
      builder: (context, provider, _) {
        return AuthFlowScaffold(
          title: _title,
          subtitle: _subtitle,
          headerAction: AuthHeaderAction(
            label: _backLabel,
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
          cardChild: Column(
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
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9FD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE7F3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _maskedIdentifier,
                        style: const TextStyle(
                          color: Color(0xFF10233F),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: List.generate(
                    _otpLength,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index == _otpLength - 1 ? 0 : 8,
                        ),
                        child: _OtpDigitField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          onChanged: (value) => _handleChanged(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: _verifyLabel,
                isLoading: provider.isVerifying,
                onPressed: _verifyCode,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: provider.canResend && !provider.isSending
                    ? _resendCode
                    : null,
                child: Text(
                  _resendLabel(provider),
                  style: TextStyle(
                    color: provider.canResend
                        ? AppColors.primary
                        : const Color(0xFF8A97AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        color: Color(0xFF10233F),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF6F9FD),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE7F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
    );
  }
}
