import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../models/task_item.dart';
import '../models/calendar_event.dart';
import '../models/salary_split.dart';
import '../ui/screens/tasks/task_list_screen.dart';
import 'secure_kv_storage.dart';

class UserStorage {
  UserStorage._(this._p, this._secure);

  final SharedPreferences _p;
  final SecureKvStorage? _secure;

  static const _kTheme = 'app_theme_mode';
  static const _kLanguage = 'app_language_v1'; // 'ru' | 'en'
  static const _kTasksDaily = 'tasks_daily_v1';
  static const _kTasksLong = 'tasks_long_v1';
  static const _kTasksDailyDate = 'tasks_daily_date_v1';
  static const _kDailySummaryShownDate = 'daily_summary_shown_date_v1';
  static const _kSalarySplitLastV3 = 'salary_split_last_v3';
  static const _kSalarySplitSavedV3 = 'salary_split_saved_v3';
  static const _kSalarySplitLast = 'salary_split_last_v4';
  static const _kSalarySplitSaved = 'salary_split_saved_v4';
  static const _kCalendarEvents = 'calendar_events_v1';

  // Privacy / app lock settings (not sensitive)
  static const _kPrivacyLockEnabled = 'privacy_lock_enabled_v1';
  static const _kPrivacyAutoLockSeconds = 'privacy_autolock_seconds_v1';
  static const _kPrivacyPreventScreenshots = 'privacy_prevent_screenshots_v1';

  // Sensitive: PIN hash (if user enables app PIN).
  static const _kPrivacyPinHash = 'privacy_pin_hash_v1';

  static Future<UserStorage> open() async {
    final p = await SharedPreferences.getInstance();
    final secure = SecureKvStorage.createIfSupported();
    final s = UserStorage._(p, secure);
    await s._maybeMigrateToSecureStorage();
    return s;
  }

  ThemeMode loadTheme() {
    final t = _p.getString(_kTheme);
    switch (t) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> saveTheme(ThemeMode m) async {
    final v = m == ThemeMode.dark ? 'dark' : 'light';
    await _p.setString(_kTheme, v);
  }

  String loadLanguageCode() {
    final v = _p.getString(_kLanguage);
    if (v == 'en') return 'en';
    return 'ru';
  }

  Future<void> saveLanguageCode(String code) async {
    final v = code == 'en' ? 'en' : 'ru';
    await _p.setString(_kLanguage, v);
  }

  Future<List<TaskItem>> loadTasks(TaskKind kind) async {
    final key = _tasksKey(kind);
    final raw = await _readSensitive(key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (m) => TaskItem.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .where((t) => t.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveTasks(TaskKind kind, List<TaskItem> tasks) async {
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _writeSensitive(_tasksKey(kind), raw);
  }

  DateTime? loadDailyTasksDate() {
    final raw = _p.getString(_kTasksDailyDate);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveDailyTasksDate(DateTime d) async {
    // Store as YYYY-MM-DD (local).
    final v =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _p.setString(_kTasksDailyDate, v);
  }

  DateTime? loadDailySummaryShownDate() {
    final raw = _p.getString(_kDailySummaryShownDate);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveDailySummaryShownDate(DateTime d) async {
    // Store as YYYY-MM-DD (local).
    final v =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _p.setString(_kDailySummaryShownDate, v);
  }

  bool loadPrivacyLockEnabled() => _p.getBool(_kPrivacyLockEnabled) ?? false;
  Future<void> savePrivacyLockEnabled(bool v) =>
      _p.setBool(_kPrivacyLockEnabled, v);

  int loadPrivacyAutoLockSeconds() => _p.getInt(_kPrivacyAutoLockSeconds) ?? 0;
  Future<void> savePrivacyAutoLockSeconds(int v) =>
      _p.setInt(_kPrivacyAutoLockSeconds, v);

  bool loadPrivacyPreventScreenshots() =>
      _p.getBool(_kPrivacyPreventScreenshots) ?? true;
  Future<void> savePrivacyPreventScreenshots(bool v) =>
      _p.setBool(_kPrivacyPreventScreenshots, v);

  Future<String?> loadPrivacyPinHash() => _readSensitive(_kPrivacyPinHash);
  Future<void> savePrivacyPinHash(String hash) => _writeSensitive(_kPrivacyPinHash, hash);
  Future<void> clearPrivacyPin() => _secure?.delete(_kPrivacyPinHash) ?? Future.value();

  Future<SalarySplitDraft> loadSalarySplitDraft() async {
    // Prefer newest schema, but fall back to v3.
    final raw =
        await _readSensitive(_kSalarySplitLast) ?? await _readSensitive(_kSalarySplitLastV3);
    if (raw == null || raw.trim().isEmpty) {
      return const SalarySplitDraft(
        salary: 0,
        percents: {},
        customAmounts: {},
        mode: SalarySplitMode.percent,
        manualAmounts: {},
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const SalarySplitDraft(
        salary: 0,
        percents: {},
        customAmounts: {},
        mode: SalarySplitMode.percent,
        manualAmounts: {},
      );
    }
    return SalarySplitDraft.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<void> saveSalarySplitDraft(SalarySplitDraft draft) async {
    await _writeSensitive(_kSalarySplitLast, jsonEncode(draft.toJson()));
  }

  Future<List<SalarySplitSaved>> loadSavedSalarySplits() async {
    final raw = await _readSensitive(_kSalarySplitSaved) ??
        await _readSensitive(_kSalarySplitSavedV3);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (m) => SalarySplitSaved.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .where((r) => r.savedAtMs > 0)
        .toList(growable: false);
  }

  Future<void> saveSavedSalarySplits(List<SalarySplitSaved> list) async {
    await _writeSensitive(
      _kSalarySplitSaved,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<CalendarEvent>> loadCalendarEvents() async {
    final raw = await _readSensitive(_kCalendarEvents);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (m) => CalendarEvent.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .where((e) => e.id.isNotEmpty && e.dateKey.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveCalendarEvents(List<CalendarEvent> events) async {
    await _writeSensitive(
      _kCalendarEvents,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }

  String _tasksKey(TaskKind kind) {
    switch (kind) {
      case TaskKind.daily:
        return _kTasksDaily;
      case TaskKind.long:
        return _kTasksLong;
    }
  }

  Future<String?> _readSensitive(String key) async {
    if (_secure == null) return _p.getString(key);
    final v = await _secure!.read(key);
    if (v != null && v.trim().isNotEmpty) return v;
    // Fallback for pre-migration users.
    return _p.getString(key);
  }

  Future<void> _writeSensitive(String key, String value) async {
    if (_secure == null) {
      await _p.setString(key, value);
      return;
    }
    await _secure!.write(key, value);
    // Keep a non-sensitive pointer? For now, store nothing in prefs.
    await _p.remove(key);
  }

  Future<void> _maybeMigrateToSecureStorage() async {
    if (_secure == null) return;
    const keys = <String>[
      _kTasksDaily,
      _kTasksLong,
      _kSalarySplitLast,
      _kSalarySplitLastV3,
      _kSalarySplitSaved,
      _kSalarySplitSavedV3,
      _kCalendarEvents,
    ];
    for (final key in keys) {
      // If secure already has value, prefer it and clean prefs.
      final existing = await _secure!.read(key);
      if (existing != null && existing.trim().isNotEmpty) {
        await _p.remove(key);
        continue;
      }
      final raw = _p.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;
      await _secure!.write(key, raw);
      await _p.remove(key);
    }
  }

  Future<void> wipeAllUserData() async {
    // Keep theme? Spec says full reset should wipe everything.
    await _p.clear();
    await _secure?.deleteAll();
  }
}

