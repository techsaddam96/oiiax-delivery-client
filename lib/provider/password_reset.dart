import 'dart:async';

import 'package:blockatie/services/auth_api_service.dart';
import 'package:flutter/material.dart';

class PasswordResetProvider extends ChangeNotifier {
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isResetting = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;
  String? _lastIdentifier;
  String? _verifiedCode;

  bool get isSending => _isSending;
  bool get isVerifying => _isVerifying;
  bool get isResetting => _isResetting;
  int get resendSecondsRemaining => _resendSecondsRemaining;
  bool get canResend => _resendSecondsRemaining <= 0 && !_isSending;
  String? get lastIdentifier => _lastIdentifier;
  String? get verifiedCode => _verifiedCode;

  Future<AuthApiResult> sendCode(String identifier) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    if (_isSending) {
      return const AuthApiResult(
        success: false,
        code: 'REQUEST_IN_PROGRESS',
        message: 'Request already in progress',
      );
    }

    _isSending = true;
    notifyListeners();

    try {
      final result = await AuthApiService.sendResetCode(
        identifier: normalizedIdentifier,
      );
      if (result.success) {
        _lastIdentifier = normalizedIdentifier;
        _verifiedCode = null;
        _startResendCountdown();
      }
      return result;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<AuthApiResult> resendCode() async {
    final identifier = _lastIdentifier;
    if (identifier == null || identifier.isEmpty) {
      return const AuthApiResult(
        success: false,
        code: 'MISSING_IDENTIFIER',
        message: 'Missing reset identifier',
      );
    }
    if (!canResend) {
      return const AuthApiResult(
        success: false,
        code: 'RESEND_BLOCKED',
        message: 'Resend is not available yet',
      );
    }
    return sendCode(identifier);
  }

  Future<AuthApiResult> verifyCode({
    required String identifier,
    required String code,
  }) async {
    if (_isVerifying) {
      return const AuthApiResult(
        success: false,
        code: 'REQUEST_IN_PROGRESS',
        message: 'Request already in progress',
      );
    }

    _isVerifying = true;
    notifyListeners();

    try {
      final result = await AuthApiService.verifyResetCode(
        identifier: identifier.trim().toLowerCase(),
        code: code.trim(),
      );
      if (result.success) {
        _lastIdentifier = identifier.trim().toLowerCase();
        _verifiedCode = code.trim();
      }
      return result;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<AuthApiResult> resetPassword({
    required String identifier,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    if (_isResetting) {
      return const AuthApiResult(
        success: false,
        code: 'REQUEST_IN_PROGRESS',
        message: 'Request already in progress',
      );
    }

    _isResetting = true;
    notifyListeners();

    try {
      final result = await AuthApiService.resetPassword(
        identifier: identifier.trim().toLowerCase(),
        code: code.trim(),
        password: password,
        confirmPassword: confirmPassword,
      );
      if (result.success) {
        clearFlow();
      }
      return result;
    } finally {
      _isResetting = false;
      notifyListeners();
    }
  }

  void _startResendCountdown([int seconds = 60]) {
    _resendTimer?.cancel();
    _resendSecondsRemaining = seconds;
    notifyListeners();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        _resendSecondsRemaining = 0;
      } else {
        _resendSecondsRemaining -= 1;
      }
      notifyListeners();
    });
  }

  void bindIdentifier(String identifier) {
    _lastIdentifier = identifier.trim();
    notifyListeners();
  }

  void clearFlow() {
    _resendTimer?.cancel();
    _resendTimer = null;
    _resendSecondsRemaining = 0;
    _lastIdentifier = null;
    _verifiedCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
