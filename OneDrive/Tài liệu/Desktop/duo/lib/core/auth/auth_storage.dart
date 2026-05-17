import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'atmos_jwt';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(const FlutterSecureStorage());
});

class AuthStorage {
  AuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
