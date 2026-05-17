import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_models.dart';
import 'auth_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  );
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AtmosUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AtmosUser?> {
  @override
  Future<AtmosUser?> build() async {
    return ref.read(authServiceProvider).getCurrentUser();
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(authServiceProvider).getCurrentUser());
  }
}

class AuthService {
  AuthService(this._dio, this._storage);

  final Dio _dio;
  final AuthStorage _storage;

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
    return _persistSession(response.data!);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _persistSession(response.data!);
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = AtmosUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveToken(token);
    return AuthSession(token: token, user: user);
  }

  Future<AtmosUser?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AtmosUser.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearToken();
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _storage.clearToken();
  }
}
