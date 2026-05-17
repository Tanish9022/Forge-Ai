import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(const FlutterSecureStorage(), LocalAuthentication());
});

class AppLockService {
  AppLockService(this._storage, this._auth);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _pinKey = 'atmos_app_pin';
  static const _biometricKey = 'atmos_app_biometric_enabled';

  Future<bool> isAppLockEnabled() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<void> enableAppLock(String pin, bool useBiometrics) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _biometricKey, value: useBiometrics.toString());
  }

  Future<void> disableAppLock() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  Future<bool> authenticateBiometric() async {
    final isEnabled = await _storage.read(key: _biometricKey);
    if (isEnabled != 'true') return false;

    final canCheckBiometrics = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Atmos',
      );
    } catch (e) {
      return false;
    }
  }
}
