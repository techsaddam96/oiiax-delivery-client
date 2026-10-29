// Password Security V2 in the Client App: the shared password policy, the
// rotated key after a password change, the session ending when the server
// refuses the old key, and the reset flow keeping codes and passwords off disk.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/utils/password_policy.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service_secure_storage_test.dart' show MemorySecureStore;

typedef _Reply = (int, Map<String, dynamic>);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);

  final _Reply Function(RequestOptions options) reply;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    final (status, body) = reply(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter adapter) =>
    Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;

const _specialPassword = "Pa'ss\"wo\\rd1";

void main() {
  late MemorySecureStore secure;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secure = MemorySecureStore();
    AuthService.configureForTesting(
      secureStore: secure,
      sessionLogout: ({
        required clientId,
        required apiKey,
        required rememberToken,
        required deviceId,
      }) async =>
          const AuthApiResult(
        success: true,
        code: 'LOGOUT_SUCCESS',
        message: 'Logged out.',
        statusCode: 200,
      ),
    );
  });

  tearDown(AuthService.resetForTesting);

  group('shared password policy (matches the server)', () {
    test('accepts 10+ characters with upper, lower and digit', () {
      expect(PasswordPolicy.message('Abcdefgh12', isArabic: false), isNull);
      expect(PasswordPolicy.message(_specialPassword, isArabic: false), isNull);
    });

    test('refuses short, over 72 bytes, missing classes and edge spaces', () {
      for (final weak in [
        'Abc12',
        'Aa1${'a' * 70}',
        'abcdefgh12',
        'ABCDEFGH12',
        'Abcdefghij',
        ' Abcdefg12',
        'Abcdefg12 ',
      ]) {
        expect(PasswordPolicy.message(weak, isArabic: false), isNotNull,
            reason: weak);
      }
    });
  });

  group('a refused key ends the session', () {
    Future<bool> endsSession(int status, Map<String, dynamic> body) async {
      await AuthService.saveApiKey('old-key', '12');
      final before = UserSessionState.generation;
      final dio = sessionDio(BaseOptions(
        baseUrl: 'https://example.invalid',
        validateStatus: (_) => true,
      ))
        ..httpClientAdapter = _Adapter((_) => (status, body));
      try {
        await dio.get<dynamic>(
          '/x',
          options: Options(headers: {'X-API-KEY': 'old-key'}),
        );
      } catch (_) {
        // A response that ended the session is rejected as stale.
      }
      return UserSessionState.generation != before;
    }

    test('401 signs out and clears the stored key', () async {
      expect(await endsSession(401, {'status': 'error'}), isTrue);
      expect(secure.values['client_api_key'], isNull);
    });

    test('403 INVALID_API_KEY (rotated key) signs out', () async {
      expect(
        await endsSession(403, {'status': 'error', 'code': 'INVALID_API_KEY'}),
        isTrue,
      );
      expect(secure.values['client_api_key'], isNull);
    });

    test('an ordinary 403 does not sign out', () async {
      expect(
        await endsSession(403, {'status': 'error', 'code': 'FORBIDDEN'}),
        isFalse,
      );
      expect(secure.values['client_api_key'], 'old-key');
    });
  });

  group('password change from the profile', () {
    test('sends the password untouched and continues with the rotated key',
        () async {
      await AuthService.saveApiKey('old-key', '12');
      final adapter = _Adapter((options) =>
          options.uri.path.endsWith('update_client_info.php')
              ? (
                  200,
                  {
                    'status': 'success',
                    'code': 'PROFILE_UPDATED',
                    'message_en': 'Profile updated.',
                    'api_key': 'rotated-key',
                  }
                )
              : (200, {'status': 'error'}));
      final provider = ProfileProvider(
        profileDio: _dio(adapter),
        statisticsDio: _dio(adapter),
        updateDio: _dio(adapter),
      );
      secure.values['client_remember_token'] = 'revoked-by-server';
      final generationBefore = UserSessionState.generation;

      final result = await provider.updateClientProfile(
        clientName: 'Client',
        storeName: 'Store',
        locationText: 'Amman',
        password: _specialPassword,
      );

      expect(result.success, isTrue, reason: result.message);
      expect(UserSessionState.generation, generationBefore,
          reason: 'same account: data is kept, nobody is signed out here');
      expect(secure.values['client_remember_token'], isNull);
      final update = adapter.seen.firstWhere(
          (o) => o.uri.path.endsWith('update_client_info.php'));
      expect(update.headers['X-API-KEY'], 'old-key');
      final sent = (update.data as FormData)
          .fields
          .firstWhere((field) => field.key == 'passclient')
          .value;
      expect(sent, _specialPassword, reason: 'no trim or escaping');
      expect(secure.values['client_api_key'], 'rotated-key');
      expect(AuthService.currentSession?.apiKey, 'rotated-key');

      final prefs = await SharedPreferences.getInstance();
      final stored = [
        ...secure.values.values,
        ...prefs.getKeys().map((k) => '${prefs.get(k)}'),
      ];
      expect(stored.any((v) => v.contains(_specialPassword)), isFalse,
          reason: 'the password is never persisted');
      provider.dispose();
    });

    test('a weak or edge-spaced password is refused before any request',
        () async {
      await AuthService.saveApiKey('old-key', '12');
      final adapter = _Adapter((_) => (200, {'status': 'success'}));
      final provider = ProfileProvider(
        profileDio: _dio(adapter),
        statisticsDio: _dio(adapter),
        updateDio: _dio(adapter),
      );
      for (final weak in ['short1A', 'abcdefgh12', ' Abcdefgh12']) {
        final result = await provider.updateClientProfile(
          clientName: 'Client',
          storeName: 'Store',
          locationText: 'Amman',
          password: weak,
        );
        expect(result.success, isFalse, reason: weak);
      }
      expect(adapter.seen, isEmpty);
      expect(secure.values['client_api_key'], 'old-key');
      provider.dispose();
    });
  });

  test('the reset screens never store or print the code or password', () {
    for (final path in [
      'lib/views/pages/auth/forget/forgetPassword.dart',
      'lib/views/pages/auth/verifyOtp/verify_otp.dart',
      'lib/views/pages/auth/resetPassword/reset_password.dart',
    ]) {
      final source = File(path).readAsStringSync();
      for (final forbidden in [
        'SharedPreferences',
        'SecureStorage',
        'AuthSecureStore',
        'print(',
        'log(',
      ]) {
        expect(source.contains(forbidden), isFalse,
            reason: '$path uses $forbidden');
      }
    }
  });
}
