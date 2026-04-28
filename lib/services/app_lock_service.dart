import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'user_storage.dart';

class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.autoLockSeconds,
    required this.preventScreenshots,
  });

  final bool enabled;
  /// 0 = lock immediately on background.
  final int autoLockSeconds;
  final bool preventScreenshots;

  AppLockSettings copyWith({
    bool? enabled,
    int? autoLockSeconds,
    bool? preventScreenshots,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      preventScreenshots: preventScreenshots ?? this.preventScreenshots,
    );
  }
}

class AppLockService {
  AppLockService(this._storage);

  final UserStorage _storage;

  AppLockSettings loadSettings() {
    return AppLockSettings(
      enabled: _storage.loadPrivacyLockEnabled(),
      autoLockSeconds: _storage.loadPrivacyAutoLockSeconds(),
      preventScreenshots: _storage.loadPrivacyPreventScreenshots(),
    );
  }

  Future<void> saveSettings(AppLockSettings s) async {
    await _storage.savePrivacyLockEnabled(s.enabled);
    await _storage.savePrivacyAutoLockSeconds(s.autoLockSeconds);
    await _storage.savePrivacyPreventScreenshots(s.preventScreenshots);
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

