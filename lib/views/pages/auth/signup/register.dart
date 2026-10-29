import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/register.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/password_policy.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/auth/components/auth_flow_widgets.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterProvider(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();

  bool get _isArabic => AppLocalizations.isArabic;

  String get _pageTitle =>
      _isArabic ? 'إنشاء حساب جديد' : 'Create a new account';

  String get _pageSubtitle => _isArabic
      ? 'أنشئ حساب متجرك للبدء في إدارة الشحنات والطلبات بسهولة.'
      : 'Create your store account to manage shipments and orders with ease.';

  String get _sectionTitle =>
      _isArabic ? 'بيانات التسجيل' : 'Registration details';

  String get _sectionSubtitle => _isArabic
      ? 'أدخل بيانات صاحب المتجر بدقة لإكمال إنشاء الحساب.'
      : 'Enter the store owner information to complete account creation.';

  String get _ownerNameLabel =>
      _isArabic ? 'اسم صاحب المتجر' : 'Store owner name';

  String get _storeNameLabel => _isArabic ? 'اسم المتجر' : 'Store name';

  String get _phoneLabel => _isArabic ? 'رقم الهاتف' : 'Phone number';

  String get _emailLabel => _isArabic ? 'البريد الإلكتروني' : 'Email address';

  String get _passwordLabel => _isArabic ? 'كلمة المرور' : 'Password';

  String get _confirmPasswordLabel =>
      _isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';

  String get _createAccountLabel =>
      _isArabic ? 'إنشاء الحساب' : 'Create account';

  String get _successTitle =>
      _isArabic ? 'تم إنشاء الحساب بنجاح' : 'Account created successfully';

  String get _backLabel => AppTranslations.getText('back');

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<RegisterProvider>();
    final result = await provider.register();
    if (!mounted) {
      return;
    }

    if (result.success) {
      final verificationSent = result.data['verification_sent'] == true ||
          result.data['activation_pending'] == true;
      provider.clearForm();
      await CustomAlert.showSuccess(
        context: context,
        title: _isArabic ? 'تم استلام طلبك' : 'Request received',
        content: verificationSent
            ? result.message
            : (_isArabic
                ? 'تم إنشاء الحساب، لكن تعذر إرسال رمز التفعيل إلى البريد الإلكتروني حالياً. يرجى المحاولة مرة أخرى لاحقاً أو التواصل مع الدعم.'
                : 'The account was created, but the verification code could not be sent to email right now. Please try again later or contact support.'),
        buttonText: AppTranslations.getText('ok'),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
      return;
    }

    provider.passCont.clear();
    provider.confirmPassCont.clear();
    await CustomAlert.showError(
      context: context,
      title: AppTranslations.getText('error'),
      content: result.message,
      buttonText: AppTranslations.getText('ok'),
    );
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return AppTranslations.getText('client_name_required');
    }
    if (text.length < 2) {
      return _isArabic ? 'الاسم قصير جداً' : 'Name is too short';
    }
    return null;
  }

  String? _validateStoreName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return AppTranslations.getText('store_name_required');
    }
    if (text.length < 2) {
      return _isArabic ? 'اسم المتجر قصير جداً' : 'Store name is too short';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final provider = context.read<RegisterProvider>();
    final normalized = provider.normalizePhoneInput(value ?? '');
    if (normalized.isEmpty) {
      return AppTranslations.getText('phone_number_required');
    }
    if (!RegExp(r'^07(7|8|9)\d{7}$').hasMatch(normalized)) {
      return AppTranslations.getText('phone_valid');
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return AppTranslations.getText('email_required');
    }

    const pattern = r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$";
    final emailRegex = RegExp(pattern, caseSensitive: false);
    if (!emailRegex.hasMatch(email)) {
      return AppTranslations.getText('invalid_email');
    }
    return null;
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
    final provider = context.read<RegisterProvider>();
    if ((value ?? '').isEmpty) {
      return _isArabic
          ? 'يرجى تأكيد كلمة المرور'
          : 'Please confirm your password';
    }
    if (value != provider.passCont.text) {
      return AppTranslations.getText('passwords_dont_match');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, _) {
        return AuthFlowScaffold(
          title: _pageTitle,
          subtitle: _pageSubtitle,
          headerAction: AuthHeaderAction(
            label: _backLabel,
            icon: _isArabic
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded,
            onTap: () => Nav.offAll(const LoginPage()),
          ),
          cardChild: AutofillGroup(
            child: Form(
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
                    controller: provider.clientNameCont,
                    hintText: _ownerNameLabel,
                    icon: Icons.person_rounded,
                    validator: _validateName,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: provider.storeNameCont,
                    hintText: _storeNameLabel,
                    icon: Icons.storefront_rounded,
                    validator: _validateStoreName,
                    autofillHints: const [AutofillHints.organizationName],
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: provider.phoneCont,
                    hintText: _phoneLabel,
                    icon: Icons.phone_rounded,
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9٠-٩+\-\s]'),
                      ),
                    ],
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: provider.emailCont,
                    hintText: _emailLabel,
                    icon: Icons.email_rounded,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: provider.passCont,
                    hintText: _passwordLabel,
                    icon: Icons.lock_rounded,
                    validator: _validatePassword,
                    keyboardType: TextInputType.visiblePassword,
                    isPassword: true,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: provider.confirmPassCont,
                    hintText: _confirmPasswordLabel,
                    icon: Icons.lock_outline_rounded,
                    validator: _validateConfirmPassword,
                    keyboardType: TextInputType.visiblePassword,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(context),
                  ),
                  const SizedBox(height: 22),
                  AuthPrimaryButton(
                    label: _createAccountLabel,
                    isLoading: provider.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                ],
              ),
            ),
          ),
          footer: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                AppTranslations.getText('already_have_account'),
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
