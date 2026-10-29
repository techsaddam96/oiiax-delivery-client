import 'dart:async';
import 'package:blockatie/services/user_session_state.dart';

import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:flutter/material.dart';

typedef ClientLoginCall = Future<AuthApiResult> Function({
  required String identifier,
  required String password,
  required bool rememberMe,
  required String deviceId,
});

typedef MessagingSyncCall = Future<void> Function({
  required String clientId,
  required String apiKey,
});

class LoginProvider extends ChangeNotifier {
  LoginProvider({ClientLoginCall? login, MessagingSyncCall? syncMessaging})
      : _login = login ?? AuthApiService.login,
        _syncMessaging =
            syncMessaging ?? FirebaseService.syncClientMessagingSetup {
    UserSessionState.register(_clearLoginForm);
  }

  bool _disposed = false;
  void _clearLoginForm() {
    phoneCont.clear();
    passCont.clear();
    _isChecked = false;
  }

  final ClientLoginCall _login;
  final MessagingSyncCall _syncMessaging;
  final TextEditingController phoneCont = TextEditingController();
  final TextEditingController passCont = TextEditingController();

  bool _isChecked = false;
  bool _isSubmitting = false;

  bool get isChecked => _isChecked;
  bool get isSubmitting => _isSubmitting;

  void toggleCheckbox() => setCheckbox(!_isChecked);

  void setCheckbox(bool value) {
    if (_isChecked == value) {
      return;
    }
    _isChecked = value;
    notifyListeners();
  }

  Future<AuthApiResult> logIn() async {
    final generation = UserSessionState.generation;
    final rememberMe = _isChecked;
    final identifier = normalizeIdentifier(phoneCont.text);
    final password = passCont.text;
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
      final deviceId = await AuthService.getOrCreateDeviceId();
      if (_disposed || generation != UserSessionState.generation) {
        throw const SessionChanged();
      }
      final result = await _login(
        identifier: identifier,
        password: password,
        rememberMe: rememberMe,
        deviceId: deviceId,
      );

      if (_disposed || generation != UserSessionState.generation) {
        throw const SessionChanged();
      }
      if (!result.success) {
        return result;
      }

      final clientData = _asMap(result.data['data']);
      final clientId = clientData['id']?.toString() ?? '';
      final apiKey = clientData['api_key']?.toString() ?? '';
      if (clientId.isEmpty || clientId == '0' || apiKey.isEmpty) {
        return const AuthApiResult(
          success: false,
          code: 'INVALID_LOGIN_RESPONSE',
          message: 'Unable to start the authenticated session.',
        );
      }

      final rememberToken = result.data['remember_token']?.toString() ?? '';
      await AuthService.saveApiKey(apiKey, clientId,
          expectedGeneration: generation,
          rememberMe: rememberMe,
          rememberToken: rememberToken);

      unawaited(_syncMessagingAfterLogin(clientId: clientId, apiKey: apiKey));

      if (!_disposed) passCont.clear();
      return result;
    } on SessionChanged {
      return const AuthApiResult(
          success: false,
          code: 'SESSION_CHANGED',
          message: 'Session changed. Please sign in again.');
    } catch (_) {
      return const AuthApiResult(
          success: false,
          code: 'SESSION_SAVE_FAILED',
          message: 'Unable to securely start the session. Please try again.');
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  String normalizeIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }

    var digits = _normalizeDigits(trimmed).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00962')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('962')) {
      digits = digits.substring(3);
    }
    if (digits.isNotEmpty && !digits.startsWith('0')) {
      digits = '0$digits';
    }
    return digits;
  }

  Future<void> _syncMessagingAfterLogin({
    required String clientId,
    required String apiKey,
  }) async {
    try {
      await _syncMessaging(
        clientId: clientId,
        apiKey: apiKey,
      );
    } catch (_) {
      // FCM registration must never block a successful login.
    }
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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  @override
  void dispose() {
    UserSessionState.unregister(_clearLoginForm);
    _disposed = true;
    phoneCont.dispose();
    passCont.dispose();
    super.dispose();
  }
}
