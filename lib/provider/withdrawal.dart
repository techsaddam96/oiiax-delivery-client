import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/withdrawal_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class WithdrawalProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _selectedOption = 'cash';
    _isLoading = false;
    _error = null;
    _lastMessage = null;
    _lastCode = null;
    _amount = '0 JOD';
    _amountTextEditing.clear();
    _showAgreement = false;
    _agreedToTerms = false;
  }

  String _selectedOption = 'cash';
  bool _isLoading = false;
  String? _error;
  String? _lastMessage;
  String? _lastCode;

  String _amount = '0 JOD';
  final TextEditingController _amountTextEditing = TextEditingController();
  bool _showAgreement = false;
  bool _agreedToTerms = false;
  bool _isBalanceHidden = false;

  String get selectedOption => _selectedOption;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isLoading;
  String? get error => _error;
  String? get lastError => _error;
  String? get lastMessage => _lastMessage;
  String? get lastCode => _lastCode;
  String get amount => _amount;
  TextEditingController get amountTextEditing => _amountTextEditing;
  bool get showAgreement => _showAgreement;
  bool get agreedToTerms => _agreedToTerms;
  bool get isBalanceHidden => _isBalanceHidden;

  void selectOption(String option) {
    final normalized = option.trim().toLowerCase();
    _selectedOption = normalized == 'cliq' ? 'click' : normalized;
    notifyListeners();
  }

  void updateAmount(String newAmount) {
    _amount = newAmount;
    notifyListeners();
  }

  void addDigit(String digit) {
    if (_amount == '0 JOD' || _amount == '0.00 JOD') {
      _amount = '$digit JOD';
    } else {
      final currentAmount = _amount.replaceAll(' JOD', '');
      if (currentAmount.length < 10) {
        _amount = '$currentAmount$digit JOD';
      }
    }
    notifyListeners();
  }

  void removeLastDigit() {
    final currentAmount = _amount.replaceAll(' JOD', '');
    if (currentAmount.length > 1) {
      final newAmount = currentAmount.substring(0, currentAmount.length - 1);
      _amount = '$newAmount JOD';
    } else {
      _amount = '0 JOD';
    }
    notifyListeners();
  }

  void clear() {
    _amount = '0 JOD';
    _showAgreement = false;
    _agreedToTerms = false;
    _error = null;
    _lastMessage = null;
    _lastCode = null;
    notifyListeners();
  }

  void showAgreementSection() {
    _showAgreement = true;
    notifyListeners();
  }

  void hideAgreementSection() {
    _showAgreement = false;
    notifyListeners();
  }

  void toggleAgreement() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    _isBalanceHidden = !_isBalanceHidden;
    notifyListeners();
  }

  Future<bool> submitCustomWithdrawalRequest({
    required double requestedAmount,
    required String withdrawalMethod,
    String accountDetails = '',
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      final result = await guardSession(
          _submitRequest(
            amountText: requestedAmount.toStringAsFixed(2),
            withdrawalMethod: withdrawalMethod,
            accountDetails: accountDetails,
            requireAgreement: false,
          ),
          sessionGeneration);
      return result['success'] == true;
    } on SessionChanged {
      return false;
    }
  }

  Future<Map<String, dynamic>> submitWithdrawalRequest() {
    final numericAmount = _amount.replaceAll(' JOD', '').trim();
    return _submitRequest(
      amountText: numericAmount,
      withdrawalMethod: _selectedOption,
      requireAgreement: true,
    );
  }

  Future<Map<String, dynamic>> _submitRequest({
    required String amountText,
    required String withdrawalMethod,
    bool requireAgreement = true,
    String accountDetails = '',
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoading) {
        return {
          'success': false,
          'message': _text(
            'A request is already in progress.',
            'يوجد طلب قيد الإرسال بالفعل.',
          ),
          'data': const <String, dynamic>{},
        };
      }

      if (requireAgreement && !_agreedToTerms) {
        _error = _text(
          'Please agree to the terms and conditions.',
          'يرجى الموافقة على الشروط والأحكام.',
        );
        notifyListeners();
        return {
          'success': false,
          'message': _error,
          'data': const <String, dynamic>{},
        };
      }

      final amountValue = double.tryParse(amountText);
      if (amountValue == null || amountValue <= 0) {
        _error = _text(
          'Please enter a valid amount.',
          'يرجى إدخال مبلغ صحيح.',
        );
        notifyListeners();
        return {
          'success': false,
          'message': _error,
          'data': const <String, dynamic>{},
        };
      }

      _isLoading = true;
      _error = null;
      _lastMessage = null;
      _lastCode = null;
      notifyListeners();

      try {
        final result = await guardSession(
            WithdrawalService.addWithdrawalRequest(
              amount: amountValue.toStringAsFixed(2),
              withdrawalMethod: withdrawalMethod,
              accountDetails: accountDetails,
            ),
            sessionGeneration);

        _lastCode = result['code']?.toString();
        if (result['success'] == true) {
          _lastMessage = result['message']?.toString();
          _error = null;
        } else {
          _error = result['message']?.toString() ??
              _text(
                'Unable to send withdrawal request. Please try again.',
                'تعذر إرسال طلب السحب. حاول مرة أخرى.',
              );
        }

        return result;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _error = _text(
          'Unable to send withdrawal request. Please try again.',
          'تعذر إرسال طلب السحب. حاول مرة أخرى.',
        );
        return {
          'success': false,
          'message': _error,
          'data': const <String, dynamic>{},
        };
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return {
        'success': false,
        'code': 'SESSION_CHANGED',
        'data': <String, dynamic>{}
      };
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _text(String en, String ar) => AppLocalizations.isArabic ? ar : en;

  @override
  void dispose() {
    _amountTextEditing.dispose();
    super.dispose();
  }
}
