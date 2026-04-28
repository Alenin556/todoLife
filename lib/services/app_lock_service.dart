import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'user_storage.dart';

class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.autoLockSeconds,
    required this.preventScreenshots,
    required this.biometricEnabled,
  });

  final bool enabled;
  /// 0 = lock immediately on background.
  final int autoLockSeconds;
  final bool preventScreenshots;
  final bool biometricEnabled;

  AppLockSettings copyWith({
    bool? enabled,
    int? autoLockSeconds,
    bool? preventScreenshots,
    bool? biometricEnabled,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      preventScreenshots: preventScreenshots ?? this.preventScreenshots,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class AppLockService {
  AppLockService(this._storage, {LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final UserStorage _storage;
  final LocalAuthentication _auth;

  AppLockSettings loadSettings() {
    return AppLockSettings(
      enabled: _storage.loadPrivacyLockEnabled(),
      autoLockSeconds: _storage.loadPrivacyAutoLockSeconds(),
      preventScreenshots: _storage.loadPrivacyPreventScreenshots(),
      biometricEnabled: _storage.loadPrivacyBiometricEnabled(),
    );
  }

  Future<void> saveSettings(AppLockSettings s) async {
    await _storage.savePrivacyLockEnabled(s.enabled);
    await _storage.savePrivacyAutoLockSeconds(s.autoLockSeconds);
    await _storage.savePrivacyPreventScreenshots(s.preventScreenshots);
    await _storage.savePrivacyBiometricEnabled(s.biometricEnabled);
  }

  Future<bool> deviceAuthAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canBiometric = await _auth.canCheckBiometrics;
      return supported || canBiometric;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithDevice({
    String reason = 'Разблокировать приложение',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasPin() async {
    final h = await _storage.loadPrivacyPinHash();
    return h != null && h.trim().isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.savePrivacyPinHash(hashPin(pin));
  }

  Future<void> clearPin() async {
    await _storage.clearPrivacyPin();
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.loadPrivacyPinHash();
    if (stored == null || stored.trim().isEmpty) return false;
    return stored == hashPin(pin);
  }
}

