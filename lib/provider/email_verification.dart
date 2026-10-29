import 'dart:async';

import 'package:blockatie/services/auth_api_service.dart';
import 'package:flutter/foundation.dart';

class EmailVerificationProvider extends ChangeNotifier {
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _timer;

  bool get isVerifying => _isVerifying;
  bool get isResending => _isResending;
  int get resendSeconds => _resendSeconds;
  bool get canResend => _resendSeconds == 0 && !_isResending;

  EmailVerificationProvider() {
    _startTimer();
  }

  Future<AuthApiResult> verify({
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
      return await AuthApiService.verifyEmail(
        identifier: identifier,
        code: code,
      );
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<AuthApiResult> resend(String identifier) async {
    if (!canResend) {
      return const AuthApiResult(
        success: false,
        code: 'RESEND_BLOCKED',
        message: 'Resend is not available yet',
      );
    }
    _isResending = true;
    notifyListeners();
    try {
      final result = await AuthApiService.resendEmailVerification(
        identifier: identifier,
      );
      if (result.success) {
        _startTimer();
      }
      return result;
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        _resendSeconds = 0;
        timer.cancel();
      } else {
        _resendSeconds -= 1;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
