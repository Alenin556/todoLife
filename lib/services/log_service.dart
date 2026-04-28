import 'dart:convert';

import 'user_storage.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  const LogEntry({
    required this.tsIso,
    required this.level,
    required this.message,
    this.stack,
  });

  final String tsIso;
  final LogLevel level;
  final String message;
  final String? stack;

  Map<String, Object?> toJson() => {
        'ts': tsIso,
        'level': level.name,
        'msg': message,
        if (stack != null) 'stack': stack,
      };

  static LogEntry? tryFromJson(Object? v) {
    if (v is! Map) return null;
    final ts = v['ts']?.toString();
    final lvl = v['level']?.toString();
    final msg = v['msg']?.toString();
    if (ts == null || ts.isEmpty) return null;
    if (msg == null || msg.isEmpty) return null;
    final level = LogLevel.values.cast<LogLevel?>().firstWhere(
          (e) => e?.name == lvl,
          orElse: () => LogLevel.info,
        )!;
    final st = v['stack']?.toString();
    return LogEntry(tsIso: ts, level: level, message: msg, stack: st);
  }
}

/// Small in-app ring buffer for diagnostics.
class LogService {
  LogService(this._storage, {this.capacity = 120});

  final UserStorage _storage;
  final int capacity;

  final List<LogEntry> _buf = <LogEntry>[];
  bool _loaded = false;
  bool _saving = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final raw = _storage.loadBugLogJson();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final it in decoded) {
        final e = LogEntry.tryFromJson(it);
        if (e != null) _buf.add(e);
      }
      if (_buf.length > capacity) {
        _buf.removeRange(0, _buf.length - capacity);
      }
    } catch (_) {
      // Ignore corrupted log.
    }
  }

  List<LogEntry> snapshot() => List.unmodifiable(_buf);

  void info(String message) => _add(LogLevel.info, message);
  void warning(String message) => _add(LogLevel.warning, message);
  void error(String message, {String? stack}) =>
      _add(LogLevel.error, message, stack: stack);

  void _add(LogLevel level, String message, {String? stack}) {
    final ts = DateTime.now().toIso8601String();
    final e = LogEntry(tsIso: ts, level: level, message: message, stack: stack);
    _buf.add(e);
    if (_buf.length > capacity) _buf.removeAt(0);
    // ignore: discarded_futures
    _persist();
  }

  Future<void> _persist() async {
    if (_saving) return;
    _saving = true;
    try {
      final raw = jsonEncode(_buf.map((e) => e.toJson()).toList());
      await _storage.saveBugLogJson(raw);
    } catch (_) {
      // Best-effort only.
    } finally {
      _saving = false;
    }
  }
}

