import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class AndroidSecureScreen {
  static const MethodChannel _ch = MethodChannel('todolife/privacy');

  static Future<void> setSecure(bool enabled) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('setSecure', {'enabled': enabled});
    } catch (_) {
      // ignore (older Android embedding / missing channel)
    }
  }
}

