import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Minimal anonymous analytics sender.
///
/// By default it does not send anything unless ANALYTICS_ENDPOINT is provided via
/// --dart-define=ANALYTICS_ENDPOINT=https://... at build/run time.
class AnalyticsService {
  AnalyticsService();

  static const String endpoint =
      String.fromEnvironment('ANALYTICS_ENDPOINT', defaultValue: '');
  static const String apiKey =
      String.fromEnvironment('ANALYTICS_API_KEY', defaultValue: '');
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '');

  bool _enabled = false;
  bool get enabled => _enabled;

  void setEnabled(bool v) => _enabled = v;

  Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    if (!_enabled) return;

    final payload = <String, Object?>{
      'name': name,
      'ts': DateTime.now().toIso8601String(),
      if (!kIsWeb) 'platform': Platform.operatingSystem,
      if (appVersion.trim().isNotEmpty) 'appVersion': appVersion,
      if (params.isNotEmpty) 'params': params,
    };

    // If endpoint isn't configured, we still keep the call as a no-op.
    if (endpoint.trim().isEmpty) return;

    // Web target not supported by this sender.
    if (kIsWeb) return;

    final uri = Uri.tryParse(endpoint);
    if (uri == null) return;

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      if (apiKey.trim().isNotEmpty) {
        req.headers.set('x-analytics-key', apiKey);
      }
      req.add(utf8.encode(jsonEncode(payload)));
      final res = await req.close();
      // Drain response to complete request.
      await res.drain<void>();
    } catch (_) {
      // Best-effort: analytics must never crash the app.
    } finally {
      client.close(force: true);
    }
  }
}

