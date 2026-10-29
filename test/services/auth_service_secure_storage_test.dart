import 'package:blockatie/provider/login.dart';
import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_secure_store.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MemorySecureStore secureStore;

  AuthApiResult validSession({String id = '12'}) => AuthApiResult(
        success: true,
        code: 'SESSION_VALID',
        message: 'Session is valid.',
        statusCode: 200,
        data: {
          'data': {'id': id},
        },
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStore = MemorySecureStore();
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => validSession(),
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

  test('successful login stores API key only in secure storage', () async {
    final provider = LoginProvider(
      login: ({
        required identifier,
        required password,
        required rememberMe,
        required deviceId,
      }) async =>
          const AuthApiResult(
        success: true,
        code: 'LOGIN_SUCCESS',
        message: 'Logged in.',
        statusCode: 200,
        data: {
          'data': {'id': 12, 'api_key': 'new-secure-key'},
        },
      ),
      syncMessaging: ({required clientId, required apiKey}) async {},
    );
    provider.phoneCont.text = '0791234567';
    provider.passCont.text = 'password';

    expect((await provider.logIn()).success, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(secureStore.values['client_api_key'], 'new-secure-key');
    expect(prefs.getString('api_key'), isNull);
    expect(prefs.getString('id'), '12');
    provider.dispose();
  });

  test('failed login does not overwrite an existing session', () async {
    await AuthService.saveApiKey('existing-key', '7');
    final provider = LoginProvider(
      login: ({
        required identifier,
        required password,
        required rememberMe,
        required deviceId,
      }) async =>
          const AuthApiResult(
        success: false,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid credentials.',
        statusCode: 401,
      ),
      syncMessaging: ({required clientId, required apiKey}) async {},
    );
    provider.phoneCont.text = '0791234567';
    provider.passCont.text = 'wrong-password';

    expect((await provider.logIn()).success, isFalse);
    expect(secureStore.values['client_api_key'], 'existing-key');
    expect((await AuthService.getSession()).clientId, '7');
    provider.dispose();
  });

  test('retrieves a secure API key', () async {
    secureStore.values['client_api_key'] = 'secure-key';
    SharedPreferences.setMockInitialValues({'id': '12'});
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => validSession(),
    );

    expect(await AuthService.getApiKey(), 'secure-key');
  });

  test('migrates the legacy key only after verified secure write', () async {
    SharedPreferences.setMockInitialValues({'id': '12', 'api_key': 'legacy'});
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => validSession(),
    );

    expect(await AuthService.getApiKey(), 'legacy');
    expect(secureStore.values['client_api_key'], 'legacy');
    expect(
        (await SharedPreferences.getInstance()).getString('api_key'), isNull);
  });

  test('keeps the legacy key when secure write fails', () async {
    SharedPreferences.setMockInitialValues({'id': '12', 'api_key': 'legacy'});
    secureStore.failWrites = true;
    AuthService.configureForTesting(secureStore: secureStore);

    expect(await AuthService.getApiKey(), 'legacy');
    expect(
      (await SharedPreferences.getInstance()).getString('api_key'),
      'legacy',
    );
  });

  test('legacy migration is idempotent', () async {
    SharedPreferences.setMockInitialValues({'id': '12', 'api_key': 'legacy'});
    AuthService.configureForTesting(secureStore: secureStore);

    await AuthService.getApiKey();
    await AuthService.getApiKey();
    expect(secureStore.writeCount, 1);
  });

  test('secure key takes precedence and removes a stale legacy key', () async {
    secureStore.values['client_api_key'] = 'secure';
    SharedPreferences.setMockInitialValues({'id': '12', 'api_key': 'stale'});
    AuthService.configureForTesting(secureStore: secureStore);

    expect(await AuthService.getApiKey(), 'secure');
    expect(
        (await SharedPreferences.getInstance()).getString('api_key'), isNull);
    expect(secureStore.writeCount, 0);
  });

  test('logout deletes secure and legacy authentication state', () async {
    secureStore.values['client_api_key'] = 'secure';
    secureStore.values['client_remember_token'] = 'remember';
    SharedPreferences.setMockInitialValues({
      'id': '12',
      'api_key': 'legacy',
      'remember_me_enabled': true,
      'language_code': 'ar',
    });
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => validSession(),
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
      ),
    );

    await AuthService.logout();
    final prefs = await SharedPreferences.getInstance();
    expect(secureStore.values['client_api_key'], isNull);
    expect(secureStore.values['client_remember_token'], isNull);
    expect(prefs.getString('api_key'), isNull);
    expect(prefs.getString('id'), isNull);
    expect(prefs.getString('language_code'), 'ar');
  });

  test('restore validates a secure session against the backend', () async {
    secureStore.values['client_api_key'] = 'secure';
    SharedPreferences.setMockInitialValues({'id': '12'});
    var calls = 0;
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async {
        calls++;
        expect(apiKey, 'secure');
        return validSession();
      },
    );

    expect((await AuthService.restoreSession()).isValid, isTrue);
    expect(calls, 1);
  });

  test('restore validates a migrated legacy session', () async {
    SharedPreferences.setMockInitialValues({'id': '12', 'api_key': 'legacy'});
    var validatedKey = '';
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async {
        validatedKey = apiKey;
        return validSession();
      },
    );

    expect((await AuthService.restoreSession()).isValid, isTrue);
    expect(validatedKey, 'legacy');
    expect(secureStore.values['client_api_key'], 'legacy');
  });

  test('401 validation clears all authentication state', () async {
    secureStore.values['client_api_key'] = 'invalid';
    SharedPreferences.setMockInitialValues({'id': '12'});
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => const AuthApiResult(
        success: false,
        code: 'SESSION_INVALID',
        message: 'Invalid.',
        statusCode: 401,
      ),
    );

    expect((await AuthService.restoreSession()).isValid, isFalse);
    expect(secureStore.values['client_api_key'], isNull);
    expect((await SharedPreferences.getInstance()).getString('id'), isNull);
  });

  test('network failure does not destroy a locally valid session', () async {
    secureStore.values['client_api_key'] = 'secure';
    SharedPreferences.setMockInitialValues({'id': '12'});
    AuthService.configureForTesting(
      secureStore: secureStore,
      sessionValidator: ({required apiKey}) async => const AuthApiResult(
        success: false,
        code: 'CONNECTION_ERROR',
        message: 'Offline.',
      ),
    );

    expect((await AuthService.restoreSession()).isValid, isTrue);
    expect(secureStore.values['client_api_key'], 'secure');
  });

  test('500 and 403 do not erase a valid local credential', () async {
    for (final status in [500, 403]) {
      secureStore.values['client_api_key'] = 'secure';
      SharedPreferences.setMockInitialValues({'id': '12'});
      AuthService.configureForTesting(
        secureStore: secureStore,
        sessionValidator: ({required apiKey}) async => AuthApiResult(
          success: false,
          code: 'FAILED',
          message: 'Failed.',
          statusCode: status,
        ),
      );
      expect((await AuthService.restoreSession()).isValid, isTrue);
      expect(secureStore.values['client_api_key'], 'secure');
    }
  });

  test('remember restore stores the rotated session securely', () async {
    secureStore.values['client_remember_token'] = 'remember-token';
    secureStore.values['client_auth_device_id'] = 'device-id-long-enough';
    SharedPreferences.setMockInitialValues({'remember_me_enabled': true});
    AuthService.configureForTesting(
      secureStore: secureStore,
      rememberRestorer: ({required rememberToken, required deviceId}) async =>
          const AuthApiResult(
        success: true,
        code: 'SESSION_RESTORED',
        message: 'Restored.',
        statusCode: 200,
        data: {
          'data': {'id': 15, 'api_key': 'restored-key'},
          'remember_token': 'rotated-token',
        },
      ),
    );

    expect((await AuthService.restoreSession()).isValid, isTrue);
    expect(secureStore.values['client_api_key'], 'restored-key');
    expect(secureStore.values['client_remember_token'], 'rotated-token');
  });

  test('sequential accounts replace cached and secure identity', () async {
    await AuthService.saveApiKey('first-key', '1');
    await AuthService.saveApiKey('second-key', '2');

    final session = await AuthService.getSession();
    expect(session.clientId, '2');
    expect(session.apiKey, 'second-key');
    expect(secureStore.values['client_api_key'], 'second-key');
  });
}

class MemorySecureStore implements AuthSecureStore {
  final Map<String, String> values = {};
  bool failWrites = false;
  int writeCount = 0;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    writeCount++;
    values[key] = value;
  }
}
