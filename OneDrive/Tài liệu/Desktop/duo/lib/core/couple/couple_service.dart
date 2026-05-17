import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../crypto/crypto_service.dart';
import '../auth/auth_service.dart';

final coupleServiceProvider = Provider<CoupleService>((ref) {
  return CoupleService(
    ref.watch(apiClientProvider),
    ref.watch(cryptoServiceProvider),
    ref.watch(authStateProvider.notifier),
  );
});

class CoupleService {
  CoupleService(this._dio, this._crypto, this._authNotifier);

  final Dio _dio;
  final CryptoService _crypto;
  final AuthNotifier _authNotifier;
  static const _storage = FlutterSecureStorage();
  static const _pendingCodeKey = 'atmos_pending_link_code';

  Future<String> generateCode() async {
    final response = await _dio.get<Map<String, dynamic>>('/couples/code');
    final code = response.data!['code'] as String;
    await _storage.write(key: _pendingCodeKey, value: code);
    return code;
  }

  Future<Map<String, dynamic>?> getCouple() async {
    final response = await _dio.get<Map<String, dynamic>>('/couples/me');
    final couple = response.data!['couple'] as Map<String, dynamic>?;
    final coupleId = couple?['id'] as String?;
    final pendingCode = await _storage.read(key: _pendingCodeKey);
    if (coupleId != null && pendingCode != null) {
      await _crypto.deriveAndStoreKey(code: pendingCode, coupleId: coupleId);
    }
    return couple;
  }

  Future<void> linkPartner(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/couples/link',
      data: {'code': code},
    );
    
    final coupleId = response.data!['couple']['id'] as String;
    await _storage.write(key: _pendingCodeKey, value: code);
    
    // Derive and store AES key using the code and coupleId
    await _crypto.deriveAndStoreKey(code: code, coupleId: coupleId);
    
    // Refresh auth state to get the updated user with coupleId
    await _authNotifier.refresh();
  }

  Future<void> updateTheme(String theme) async {
    await _dio.patch<Map<String, dynamic>>(
      '/couples/theme',
      data: {'theme': theme},
    );
  }

  Future<String?> updatePartnerNickname(String? nickname) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/couples/partner-nickname',
      data: {'nickname': nickname},
    );
    return response.data!['couple']['partnerNickname'] as String?;
  }
}
