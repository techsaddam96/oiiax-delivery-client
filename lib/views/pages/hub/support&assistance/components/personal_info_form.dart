import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/client_message_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class ContactFormWidget extends StatefulWidget {
  final TextTheme textTheme;

  const ContactFormWidget({super.key, required this.textTheme});

  @override
  State<ContactFormWidget> createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends State<ContactFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  bool get _isArabic => AppLocalizations.isRTL;

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _text(String ar, String en) => _isArabic ? ar : en;

  bool _isValidJordanPhone(String value) {
    final phone = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^(07[789]\d{7}|\+9627[789]\d{7}|009627[789]\d{7})$')
        .hasMatch(phone);
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value.trim());
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await ClientMessageService.sendClientMessage(
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      final success = result['success'] == true;
      final message = result['message']?.toString().trim();
      _showSnackBar(
        message?.isNotEmpty == true
            ? message!
            : success
                ? _text('تم إرسال الرسالة بنجاح.', 'Message sent successfully.')
                : _text(
                    'تعذر إرسال الرسالة. حاول مرة أخرى.',
                    'Unable to send message. Please try again.',
                  ),
        isSuccess: success,
      );

      if (success) {
        _formKey.currentState?.reset();
        _firstnameController.clear();
        _lastnameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _messageController.clear();
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        _text(
          'تعذر إرسال الرسالة. حاول مرة أخرى.',
          'Unable to send message. Please try again.',
        ),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    final color = isSuccess ? const Color(0xff16A06D) : const Color(0xffDC2626);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text('أرسل لنا رسالة', 'Send us a message'),
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _text(
                'اكتب تفاصيل المشكلة وسنقوم بالرد عليك بأقرب وقت.',
                'Tell us about your issue and we will get back to you as soon as possible.',
              ),
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _SupportTextField(
              controller: _firstnameController,
              label: _text('الاسم الأول', 'First Name'),
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 2) {
                  return _text(
                    'الاسم الأول مطلوب.',
                    'First name is required.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _SupportTextField(
              controller: _lastnameController,
              label: _text('الاسم الأخير', 'Last Name'),
              icon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 2) {
                  return _text(
                    'الاسم الأخير مطلوب.',
                    'Last name is required.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _SupportTextField(
              controller: _phoneController,
              label: _text('رقم الهاتف', 'Phone Number'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return _text(
                    'رقم الهاتف مطلوب.',
                    'Phone number is required.',
                  );
                }
                if (!_isValidJordanPhone(trimmed)) {
                  return _text(
                    'أدخل رقم أردني صحيح مثل 079xxxxxxx أو +96279xxxxxxx.',
                    'Enter a valid Jordan phone like 079xxxxxxx or +96279xxxxxxx.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _SupportTextField(
              controller: _emailController,
              label: _text('البريد الإلكتروني', 'Email'),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return _text(
                    'البريد الإلكتروني مطلوب حالياً لإرسال الطلب.',
                    'Email is currently required to send the request.',
                  );
                }
                if (!_isValidEmail(trimmed)) {
                  return _text(
                    'أدخل بريد إلكتروني صحيح.',
                    'Enter a valid email address.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _SupportTextField(
              controller: _messageController,
              label: _text('الرسالة', 'Message'),
              icon: Icons.notes_rounded,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 5,
              maxLength: 500,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 10) {
                  return _text(
                    'الرسالة يجب أن تكون 10 أحرف على الأقل.',
                    'Message must be at least 10 characters.',
                  );
                }
                if (trimmed.length > 500) {
                  return _text(
                    'الرسالة طويلة جداً.',
                    'Message is too long.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isLoading
                      ? _text('جارٍ الإرسال...', 'Sending...')
                      : _text('إرسال الرسالة', 'Send Message'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.65),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTextField extends StatelessWidget {
  const _SupportTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xffE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xffE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xffDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xffDC2626), width: 1.4),
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xffE1E8F2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

Widget buildContactForm(TextTheme textTheme) {
  return ContactFormWidget(textTheme: textTheme);
}
