import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../models/task_item.dart';
import '../models/calendar_event.dart';
import '../models/salary_split.dart';
import '../ui/screens/tasks/task_list_screen.dart';

class UserStorage {
  UserStorage._(this._p);

  final SharedPreferences _p;

  static const _kTheme = 'app_theme_mode';
  static const _kTasksDaily = 'tasks_daily_v1';
  static const _kTasksLong = 'tasks_long_v1';
  static const _kTasksDailyDate = 'tasks_daily_date_v1';
  static const _kSalarySplitLastV3 = 'salary_split_last_v3';
  static const _kSalarySplitSavedV3 = 'salary_split_saved_v3';
  static const _kSalarySplitLast = 'salary_split_last_v4';
  static const _kSalarySplitSaved = 'salary_split_saved_v4';
  static const _kCalendarEvents = 'calendar_events_v1';

  static Future<UserStorage> open() async {
    final p = await SharedPreferences.getInstance();
    return UserStorage._(p);
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

  List<TaskItem> loadTasks(TaskKind kind) {
    final raw = _p.getString(_tasksKey(kind));
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
    await _p.setString(_tasksKey(kind), raw);
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

  SalarySplitDraft loadSalarySplitDraft() {
    // Prefer newest schema, but fall back to v3.
    final raw = _p.getString(_kSalarySplitLast) ?? _p.getString(_kSalarySplitLastV3);
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
    await _p.setString(_kSalarySplitLast, jsonEncode(draft.toJson()));
  }

  List<SalarySplitSaved> loadSavedSalarySplits() {
    final raw = _p.getString(_kSalarySplitSaved) ?? _p.getString(_kSalarySplitSavedV3);
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
    await _p.setString(
      _kSalarySplitSaved,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  List<CalendarEvent> loadCalendarEvents() {
    final raw = _p.getString(_kCalendarEvents);
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
    await _p.setString(
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
}

