import 'dart:async';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/store_statistics_service.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'dart:convert';
import 'dart:math';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_secure_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientSession {
  const ClientSession({required this.clientId, required this.apiKey});
  final String? clientId;
  final String? apiKey;

  bool get isValid {
    final id = clientId?.trim() ?? '';
    final key = apiKey?.trim() ?? '';
    return id.isNotEmpty && id != '0' && key.isNotEmpty;
  }
}

typedef SessionValidator = Future<AuthApiResult> Function({
  required String apiKey,
});

typedef RememberSessionRestorer = Future<AuthApiResult> Function({
  required String rememberToken,
  required String deviceId,
});

typedef SessionLogout = Future<AuthApiResult> Function({
  required String clientId,
  required String apiKey,
  required String rememberToken,
  required String deviceId,
});

class AuthService {
  static const String _secureApiKeyKey = 'client_api_key';
  static const String _legacyApiKeyKey = 'api_key';
  static const String _userIdKey = 'id';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _clientOnboardingSeenKey = 'client_onboarding_seen';
  static const String _rememberEnabledKey = 'remember_me_enabled';
  static const String _rememberTokenKey = 'client_remember_token';
  static const String _deviceIdKey = 'client_auth_device_id';

  static AuthSecureStore _secureStore = const FlutterAuthSecureStore();
  static SessionValidator _sessionValidator = AuthApiService.validateSession;
  static RememberSessionRestorer _rememberRestorer =
      AuthApiService.restoreSession;
  static SessionLogout _sessionLogout = AuthApiService.logout;
  static SharedPreferences? _prefs;
  static ClientSession? _cachedSession;
  static Future<ClientSession>? _restoreRequest;
  static Future<void> _storageQueue = Future<void>.value();
  static ClientSession? get currentSession => _cachedSession;

  // Serialize disk writes so a delayed logout cannot erase a newer login.
  static Future<T> _exclusive<T>(Future<T> Function() action) {
    final operation = _storageQueue.then((_) => action());
    _storageQueue =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  static void _resetAccountState(SessionResetReason reason) {
    UserSessionState.reset(reason);
    StoreStatisticsService.clearCache();
    RequestIdService.clearUserState();
    _restoreRequest = null;
  }

  static Future<void> invalidateIfCurrent(String apiKey, int generation) async {
    if (generation != UserSessionState.generation ||
        _cachedSession?.apiKey != apiKey) {
      return;
    }
    await clearSession(reason: SessionResetReason.invalidSession);
  }

  static Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<ClientSession> getSession() async {
    if (_cachedSession != null) return _cachedSession!;
    final generation = UserSessionState.generation;
    return _exclusive(() async {
      if (_cachedSession != null) return _cachedSession!;
      final prefs = await _prefsInstance();
      final session = ClientSession(
        clientId: prefs.getString(_userIdKey),
        apiKey: await _readApiKeyWithLegacyMigration(prefs),
      );
      if (generation != UserSessionState.generation) {
        return _cachedSession ??
            const ClientSession(clientId: null, apiKey: null);
      }
      return _cachedSession = session;
    });
  }

  // NOTE: Remove this migration after all supported app versions have moved
  // their session credential out of SharedPreferences.
  static Future<String?> _readApiKeyWithLegacyMigration(
    SharedPreferences prefs,
  ) async {
    final legacyKey = prefs.getString(_legacyApiKeyKey)?.trim() ?? '';
    try {
      final secureKey =
          (await _secureStore.read(_secureApiKeyKey))?.trim() ?? '';
      if (secureKey.isNotEmpty) {
        if (legacyKey.isNotEmpty) await prefs.remove(_legacyApiKeyKey);
        return secureKey;
      }
      if (legacyKey.isEmpty) return null;

      await _secureStore.write(_secureApiKeyKey, legacyKey);
      final verified =
          (await _secureStore.read(_secureApiKeyKey))?.trim() ?? '';
      if (verified != legacyKey) {
        await _secureStore.delete(_secureApiKeyKey);
        throw StateError('Secure API key migration verification failed.');
      }
      await prefs.remove(_legacyApiKeyKey);
      return verified;
    } catch (_) {
      // Do not strand an existing user when secure storage is temporarily
      // unavailable. The migration is retried on the next uncached read.
      return legacyKey.isEmpty ? null : legacyKey;
    }
  }

  static Future<ClientSession> restoreSession() {
    if (_restoreRequest != null) return _restoreRequest!;
    late final Future<ClientSession> request;
    request = _restoreSessionInternal().whenComplete(() {
      if (identical(_restoreRequest, request)) _restoreRequest = null;
    });
    return _restoreRequest = request;
  }

  static Future<ClientSession> _restoreSessionInternal() async {
    final generation = UserSessionState.generation;
    final localSession = await getSession();
    if (generation != UserSessionState.generation) return _cachedSession!;

    if (localSession.isValid) {
      final validation = await _sessionValidator(apiKey: localSession.apiKey!);
      if (generation != UserSessionState.generation) return _cachedSession!;
      if (validation.success) {
        final data = _asMap(validation.data['data']);
        final validatedId = data['id']?.toString() ?? '';
        if (validatedId.isNotEmpty && validatedId != localSession.clientId) {
          await saveApiKey(localSession.apiKey!, validatedId,
              expectedGeneration: generation);
        }
        return _cachedSession ?? localSession;
      }
      if (validation.statusCode == 401) {
        await clearSession(reason: SessionResetReason.invalidSession);
        return const ClientSession(clientId: null, apiKey: null);
      }
      // Network, server, and 403 responses do not prove invalid credentials.
      return localSession;
    }

    final prefs = await _prefsInstance();
    if (!(prefs.getBool(_rememberEnabledKey) ?? false)) {
      if (generation != UserSessionState.generation) return _cachedSession!;
      await clearSession();
      return const ClientSession(clientId: null, apiKey: null);
    }

    try {
      final token = (await _secureStore.read(_rememberTokenKey))?.trim() ?? '';
      if (token.isEmpty) {
        return const ClientSession(clientId: null, apiKey: null);
      }
      final result = await _rememberRestorer(
        rememberToken: token,
        deviceId: await getOrCreateDeviceId(),
      ).timeout(const Duration(seconds: 8));
      if (generation != UserSessionState.generation) return _cachedSession!;
      if (!result.success) {
        if (result.statusCode == 401) {
          await clearSession(reason: SessionResetReason.invalidSession);
        }
        return const ClientSession(clientId: null, apiKey: null);
      }

      final client = _asMap(result.data['data']);
      final id = client['id']?.toString() ?? '';
      final key = client['api_key']?.toString() ?? '';
      if (id.isEmpty || id == '0' || key.isEmpty) {
        await clearSession();
        return const ClientSession(clientId: null, apiKey: null);
      }
      await saveApiKey(key, id,
          expectedGeneration: generation,
          rememberMe: true,
          rememberToken: result.data['remember_token']?.toString() ?? token);
      return ClientSession(clientId: id, apiKey: key);
    } catch (_) {
      // Temporary network/storage failures must not revoke a remember token.
      return const ClientSession(clientId: null, apiKey: null);
    }
  }

  static Future<bool> hasValidSession() async => (await getSession()).isValid;

  static Future<void> saveApiKey(
    String apiKey,
    String id, {
    int? expectedGeneration,
    bool? rememberMe,
    String? rememberToken,
  }) {
    final generation = expectedGeneration ?? UserSessionState.generation;
    return _exclusive(() async {
      if (generation != UserSessionState.generation) {
        throw const SessionChanged();
      }
      final key = apiKey.trim();
      final clientId = id.trim();
      if (key.isEmpty || clientId.isEmpty || clientId == '0') {
        throw ArgumentError('A valid client session is required.');
      }
      final prefs = await _prefsInstance();
      final previousKey = await _secureStore.read(_secureApiKeyKey);
      final previousId = prefs.getString(_userIdKey);
      final previousRemember = await _secureStore.read(_rememberTokenKey);
      final previousRememberEnabled = prefs.getBool(_rememberEnabledKey);
      try {
        await _secureStore.write(_secureApiKeyKey, key);
        if ((await _secureStore.read(_secureApiKeyKey))?.trim() != key) {
          throw StateError('Secure API key write verification failed.');
        }
        await prefs.setString(_userIdKey, clientId);
        await prefs.remove(_legacyApiKeyKey);
        if (generation != UserSessionState.generation) {
          throw const SessionChanged();
        }
        if (rememberMe != null) {
          await prefs.setBool(_rememberEnabledKey, rememberMe);
          if (rememberMe && (rememberToken?.trim().isNotEmpty ?? false)) {
            await _secureStore.write(_rememberTokenKey, rememberToken!.trim());
          } else {
            await _secureStore.delete(_rememberTokenKey);
          }
        } else if (_cachedSession?.clientId != clientId) {
          await prefs.remove(_rememberEnabledKey);
          await _secureStore.delete(_rememberTokenKey);
        }
        if (generation != UserSessionState.generation) {
          throw const SessionChanged();
        }
      } catch (_) {
        // A failed login commit must not leave a mixed identity on disk.
        await _restoreSecureApiKey(previousKey);
        if (previousId == null) {
          await prefs.remove(_userIdKey);
        } else {
          await prefs.setString(_userIdKey, previousId);
        }
        if (previousRemember == null) {
          await _secureStore.delete(_rememberTokenKey);
        } else {
          await _secureStore.write(_rememberTokenKey, previousRemember);
        }
        if (previousRememberEnabled == null) {
          await prefs.remove(_rememberEnabledKey);
        } else {
          await prefs.setBool(_rememberEnabledKey, previousRememberEnabled);
        }
        rethrow;
      }
      // Publish the new identity only after old account data is actually empty.
      _resetAccountState(SessionResetReason.accountChanged);
      _cachedSession = ClientSession(clientId: clientId, apiKey: key);
    });
  }

  /// Swaps the key of the signed-in client after the server rotated it (a
  /// password change). Same identity, so account data is kept — unlike
  /// [saveApiKey], which treats every save as an account switch. The server
  /// revoked every remember token, so remember-me is turned off here.
  static Future<void> replaceApiKey(String apiKey, {int? expectedGeneration}) {
    final generation = expectedGeneration ?? UserSessionState.generation;
    return _exclusive(() async {
      final current = _cachedSession;
      if (generation != UserSessionState.generation ||
          current == null ||
          !current.isValid) {
        throw const SessionChanged();
      }
      final key = apiKey.trim();
      if (key.isEmpty) {
        throw ArgumentError('A valid API key is required.');
      }
      await _secureStore.write(_secureApiKeyKey, key);
      if ((await _secureStore.read(_secureApiKeyKey))?.trim() != key) {
        throw StateError('Secure API key write verification failed.');
      }
      final prefs = await _prefsInstance();
      await prefs.setBool(_rememberEnabledKey, false);
      await _secureStore.delete(_rememberTokenKey);
      _cachedSession = ClientSession(clientId: current.clientId, apiKey: key);
    });
  }

  static Future<void> _restoreSecureApiKey(String? previousKey) async {
    if (previousKey == null || previousKey.trim().isEmpty) {
      await _secureStore.delete(_secureApiKeyKey);
    } else {
      await _secureStore.write(_secureApiKeyKey, previousKey);
    }
  }

  static Future<void> saveRememberToken(String token) async {
    if (token.trim().isNotEmpty) {
      await _secureStore.write(_rememberTokenKey, token.trim());
    }
  }

  static Future<void> setRememberMeEnabled(bool enabled) async =>
      (await _prefsInstance()).setBool(_rememberEnabledKey, enabled);

  static Future<void> clearRememberToken() async {
    try {
      await _secureStore.delete(_rememberTokenKey);
    } catch (_) {
      // API-key cleanup must continue if remember-token cleanup fails.
    }
  }

  static Future<String> getOrCreateDeviceId() async {
    try {
      final existing = (await _secureStore.read(_deviceIdKey))?.trim() ?? '';
      if (existing.length >= 16) return existing;
      final created = _randomToken();
      await _secureStore.write(_deviceIdKey, created);
      return created;
    } catch (_) {
      return _randomToken();
    }
  }

  static String _randomToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Future<String?> getApiKey() async => (await getSession()).apiKey;
  static Future<String?> getUserId() async => (await getSession()).clientId;

  static Future<bool> isClientOnboardingSeen() async =>
      (await _prefsInstance()).getBool(_clientOnboardingSeenKey) ?? false;

  static Future<void> setClientOnboardingSeen(bool seen) async =>
      (await _prefsInstance()).setBool(_clientOnboardingSeenKey, seen);

  static Future<void> clearApiKey() => clearSession();

  static Future<void> logout() {
    final session = _cachedSession;
    _cachedSession = const ClientSession(clientId: null, apiKey: null);
    _resetAccountState(SessionResetReason.logout);
    return _exclusive(() async {
      final prefs = await _prefsInstance();
      var previous =
          session ?? const ClientSession(clientId: null, apiKey: null);
      var rememberToken = '';
      var deviceId = '';
      try {
        if (session == null) {
          previous = ClientSession(
              clientId: prefs.getString(_userIdKey),
              apiKey: await _secureStore.read(_secureApiKeyKey));
        }
        rememberToken = (await _secureStore.read(_rememberTokenKey)) ?? '';
        deviceId = (await _secureStore.read(_deviceIdKey)) ?? '';
      } catch (_) {
        // Revocation metadata is best effort; local logout must still complete.
      }
      await _eraseStoredSession();
      if (previous.isValid) {
        unawaited(_revokeRemoteSession(
            clientId: previous.clientId!,
            apiKey: previous.apiKey!,
            rememberToken: rememberToken,
            deviceId: deviceId));
      }
    });
  }

  static Future<void> _revokeRemoteSession({
    required String clientId,
    required String apiKey,
    required String rememberToken,
    required String deviceId,
  }) async {
    try {
      await _sessionLogout(
        clientId: clientId,
        apiKey: apiKey,
        rememberToken: rememberToken,
        deviceId: deviceId,
      ).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Local credentials are already cleared; remote revocation is best effort.
    }
  }

  static Future<void> clearSession({
    SessionResetReason reason = SessionResetReason.logout,
  }) {
    _cachedSession = const ClientSession(clientId: null, apiKey: null);
    _resetAccountState(reason);
    return _exclusive(_eraseStoredSession);
  }

  static Future<void> _eraseStoredSession() async {
    final prefs = await _prefsInstance();
    try {
      await _secureStore.delete(_secureApiKeyKey);
    } finally {
      await prefs.remove(_legacyApiKeyKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_rememberEnabledKey);
      await clearRememberToken();
    }
  }

  static Future<Map<String, dynamic>> deleteAccount(String clientId) async {
    final generation = UserSessionState.generation;
    try {
      final response = await Dio().post(
        AppUrls.deleteAccount,
        data: {'clientId': clientId},
        options: Options(headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-API-KEY': await getApiKey(),
          'X-CLIENT-ID': clientId,
        }),
      );
      if (generation != UserSessionState.generation) {
        return {'success': false, 'message': 'Session changed.'};
      }
      final data = _asMap(response.data);
      if (response.statusCode == 200 && data['status'] == 'success') {
        await clearSession();
        return {
          'success': true,
          'message': data['message'] ?? 'Account deleted successfully',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete account',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static bool shouldAttemptRememberRestore({
    required ClientSession localSession,
    required bool rememberEnabled,
  }) =>
      rememberEnabled && !localSession.isValid;

  @visibleForTesting
  static void configureForTesting({
    required AuthSecureStore secureStore,
    SessionValidator? sessionValidator,
    RememberSessionRestorer? rememberRestorer,
    SessionLogout? sessionLogout,
  }) {
    _secureStore = secureStore;
    _sessionValidator = sessionValidator ?? AuthApiService.validateSession;
    _rememberRestorer = rememberRestorer ?? AuthApiService.restoreSession;
    _sessionLogout = sessionLogout ?? AuthApiService.logout;
    _resetCaches();
  }

  @visibleForTesting
  static void resetForTesting() {
    _secureStore = const FlutterAuthSecureStore();
    _sessionValidator = AuthApiService.validateSession;
    _rememberRestorer = AuthApiService.restoreSession;
    _sessionLogout = AuthApiService.logout;
    _resetCaches();
  }

  static void _resetCaches() {
    _prefs = null;
    _cachedSession = null;
    _restoreRequest = null;
    _storageQueue = Future<void>.value();
  }
}
