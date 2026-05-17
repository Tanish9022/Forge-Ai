import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService(const FlutterSecureStorage());
});

class CryptoService {
  CryptoService(this._storage);

  final FlutterSecureStorage _storage;
  static const _keyStorageKey = 'atmos_aes_key';

  /// Derives an AES-256 key from the 6-digit link code and couple ID.
  /// We use SHA-256 (code + coupleId) as a simple KDF for the MVP.
  Future<void> deriveAndStoreKey({
    required String code,
    required String coupleId,
  }) async {
    final salt = utf8.encode(coupleId);
    final pass = utf8.encode(code);
    final bytes = pass + salt;
    final digest = sha256.convert(bytes);
    
    // Store the 32-byte key as base64
    final keyBase64 = base64.encode(digest.bytes);
    await _storage.write(key: _keyStorageKey, value: keyBase64);
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _keyStorageKey);
  }

  Future<Key?> _getKey() async {
    final keyBase64 = await _storage.read(key: _keyStorageKey);
    if (keyBase64 == null) return null;
    return Key.fromBase64(keyBase64);
  }

  /// Encrypts plaintext. Returns a map with 'encryptedContent' and 'iv' (both base64).
  Future<Map<String, String>> encrypt(String plaintext) async {
    final key = await _getKey();
    if (key == null) throw Exception('Encryption key not found');

    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'encryptedContent': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypts ciphertext.
  Future<String> decrypt(String encryptedContentBase64, String ivBase64) async {
    final key = await _getKey();
    if (key == null) throw Exception('Encryption key not found');

    final iv = IV.fromBase64(ivBase64);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    
    return encrypter.decrypt(Encrypted.fromBase64(encryptedContentBase64), iv: iv);
  }

  /// Encrypts plaintext bytes. Returns a map with 'encryptedContent' and 'iv' (both base64).
  Future<Map<String, String>> encryptBytes(List<int> bytes) async {
    final key = await _getKey();
    if (key == null) throw Exception('Encryption key not found');

    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    return {
      'encryptedContent': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypts ciphertext to bytes.
  Future<List<int>> decryptBytes(String encryptedContentBase64, String ivBase64) async {
    final key = await _getKey();
    if (key == null) throw Exception('Encryption key not found');

    final iv = IV.fromBase64(ivBase64);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    
    return encrypter.decryptBytes(Encrypted.fromBase64(encryptedContentBase64), iv: iv);
  }
}
