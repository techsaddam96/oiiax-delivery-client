import 'package:blockatie/services/auth_api_service.dart';
import 'package:flutter/material.dart';

class RegisterProvider extends ChangeNotifier {
  RegisterProvider();

  final TextEditingController clientNameCont = TextEditingController();
  final TextEditingController storeNameCont = TextEditingController();
  final TextEditingController phoneCont = TextEditingController();
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passCont = TextEditingController();
  final TextEditingController confirmPassCont = TextEditingController();

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String normalizePhoneInput(String input) {
    var digitsOnly = _normalizeDigits(input).replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.startsWith('00962')) {
      digitsOnly = digitsOnly.substring(5);
    } else if (digitsOnly.startsWith('962')) {
      digitsOnly = digitsOnly.substring(3);
    }

    if (digitsOnly.isNotEmpty && !digitsOnly.startsWith('0')) {
      digitsOnly = '0$digitsOnly';
    }

    return digitsOnly;
  }

  String _normalizeDigits(String value) {
    const easternArabic = '٠١٢٣٤٥٦٧٨٩';
    const westernArabic = '0123456789';

    var normalized = value;
    for (var index = 0; index < easternArabic.length; index++) {
      normalized = normalized.replaceAll(
        easternArabic[index],
        westernArabic[index],
      );
    }
    return normalized;
  }

  Future<AuthApiResult> register() async {
    if (_isSubmitting) {
      return const AuthApiResult(
        success: false,
        code: 'REQUEST_IN_PROGRESS',
        message: 'Request already in progress',
      );
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      return await AuthApiService.registerClient(
        ownerName: clientNameCont.text.trim(),
        storeName: storeNameCont.text.trim(),
        phone: normalizePhoneInput(phoneCont.text),
        email: emailCont.text.trim().toLowerCase(),
        password: passCont.text,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearForm() {
    clientNameCont.clear();
    storeNameCont.clear();
    phoneCont.clear();
    emailCont.clear();
    passCont.clear();
    confirmPassCont.clear();
  }

  @override
  void dispose() {
    clientNameCont.dispose();
    storeNameCont.dispose();
    phoneCont.dispose();
    emailCont.dispose();
    passCont.dispose();
    confirmPassCont.dispose();
    super.dispose();
  }
}
