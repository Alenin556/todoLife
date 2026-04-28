import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small key/value storage backed by OS keystore/keychain.
///
/// On web this is not used (no keystore); on desktop it's best-effort.
class SecureKvStorage {
  SecureKvStorage._(this._s);

  final FlutterSecureStorage _s;

  static SecureKvStorage? createIfSupported() {
    if (kIsWeb) return null;
    // Android/iOS are the primary targets; other platforms are best-effort.
    // Keep it conservative: only enable where keystore/keychain semantics exist.
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return null;
    const s = FlutterSecureStorage();
    return SecureKvStorage._(s);
  }

  Future<String?> read(String key) => _s.read(key: key);
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  Future<void> delete(String key) => _s.delete(key: key);
  Future<void> deleteAll() => _s.deleteAll();
}

