import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthSecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterAuthSecureStore implements AuthSecureStore {
  const FlutterAuthSecureStore({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  });

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}
