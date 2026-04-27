import 'package:flutter/material.dart';

import 'models/task_item.dart';
import 'models/calendar_event.dart';
import 'models/salary_split.dart';
import 'services/user_storage.dart';
import 'ui/screens/tasks/task_list_screen.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final UserStorage _storage;

  ThemeMode _themeMode = ThemeMode.light;
  bool _ready = false;

  List<TaskItem> _dailyTasks = const [];
  List<TaskItem> _longTasks = const [];
  List<CalendarEvent> _calendarEvents = const [];
  SalarySplitDraft _salarySplitDraft =
      const SalarySplitDraft(salary: 0, percents: {}, customAmounts: {});
  List<SalarySplitSaved> _savedSalarySplits = const [];

  ThemeMode get themeMode => _themeMode;
  bool get ready => _ready;

  List<TaskItem> tasks(TaskKind kind) {
    switch (kind) {
      case TaskKind.daily:
        return _dailyTasks;
      case TaskKind.long:
        return _longTasks;
    }
  }

  Future<void> ensureDailyTasksFresh() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _storage.loadDailyTasksDate();
    final lastDay = last == null ? null : DateTime(last.year, last.month, last.day);
    if (lastDay == null || lastDay.isBefore(today)) {
      _dailyTasks = const [];
      await _storage.saveTasks(TaskKind.daily, _dailyTasks);
      await _storage.saveDailyTasksDate(today);
      notifyListeners();
    }
  }

  SalarySplitDraft get salarySplitDraft => _salarySplitDraft;
  List<SalarySplitSaved> get savedSalarySplits => _savedSalarySplits;
  List<CalendarEvent> get calendarEvents => _calendarEvents;

  Future<void> init() async {
    _themeMode = _storage.loadTheme();
    _dailyTasks = _storage.loadTasks(TaskKind.daily);
    _longTasks = _storage.loadTasks(TaskKind.long);
    _calendarEvents = _storage.loadCalendarEvents();
    await ensureDailyTasksFresh();
    _salarySplitDraft = _storage.loadSalarySplitDraft();
    _savedSalarySplits = _storage.loadSavedSalarySplits();
    _ready = true;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveTheme(mode);
    notifyListeners();
  }

  Future<void> toggleTaskDone(TaskKind kind, String id, bool done) async {
    final updated = tasks(kind)
        .map((t) => t.id == id ? t.copyWith(done: done) : t)
        .toList(growable: false);
    await _setTasks(kind, updated);
  }

  Future<void> deleteTask(TaskKind kind, String id) async {
    final updated =
        tasks(kind).where((t) => t.id != id).toList(growable: false);
    await _setTasks(kind, updated);
  }

  Future<void> clearTasks(TaskKind kind) async {
    await _setTasks(kind, const []);
  }

  Future<void> upsertTask(TaskKind kind,
      {String? id, required String text}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    final list = tasks(kind);
    final existingIndex = id == null ? -1 : list.indexWhere((t) => t.id == id);
    final updated = [...list];

    if (existingIndex >= 0) {
      updated[existingIndex] =
          updated[existingIndex].copyWith(text: normalized);
    } else {
      final newId = '$now-${normalized.hashCode}';
      updated.insert(
        0,
        TaskItem(id: newId, text: normalized, done: false, createdAtMs: now),
      );
    }

    await _setTasks(kind, updated);
    if (kind == TaskKind.daily) {
      final now = DateTime.now();
      await _storage.saveDailyTasksDate(DateTime(now.year, now.month, now.day));
    }
  }

  TaskItem? findTask(TaskKind kind, String id) {
    for (final t in tasks(kind)) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _setTasks(TaskKind kind, List<TaskItem> v) async {
    switch (kind) {
      case TaskKind.daily:
        _dailyTasks = v;
      case TaskKind.long:
        _longTasks = v;
    }
    await _storage.saveTasks(kind, v);
    if (kind == TaskKind.daily) {
      final now = DateTime.now();
      await _storage.saveDailyTasksDate(DateTime(now.year, now.month, now.day));
    }
    notifyListeners();
  }

  Future<void> updateSalarySplitDraft(SalarySplitDraft draft) async {
    _salarySplitDraft = draft;
    await _storage.saveSalarySplitDraft(draft);
    notifyListeners();
  }

  Future<void> saveCurrentSalarySplit() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = SalarySplitSaved(savedAtMs: now, draft: _salarySplitDraft);
    _savedSalarySplits = [record, ..._savedSalarySplits];
    await _storage.saveSavedSalarySplits(_savedSalarySplits);
    notifyListeners();
  }

  Future<void> setSalary(double salary) async {
    _salarySplitDraft = SalarySplitDraft(
      salary: salary,
      percents: _salarySplitDraft.percents,
      customAmounts: _salarySplitDraft.customAmounts,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> setSalaryPercent(String category, int percent) async {
    final next = Map<String, int>.from(_salarySplitDraft.percents);
    if (percent <= 0) {
      next.remove(category);
    } else {
      next[category] = percent;
    }
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: next,
      customAmounts: _salarySplitDraft.customAmounts,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> addCustomSalaryCategory(String name, double amount) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = Map<String, double>.from(_salarySplitDraft.customAmounts);
    next[trimmed] = amount;
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: _salarySplitDraft.percents,
      customAmounts: next,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> deleteCustomSalaryCategory(String name) async {
    final next = Map<String, double>.from(_salarySplitDraft.customAmounts);
    next.remove(name);
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: _salarySplitDraft.percents,
      customAmounts: next,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  List<CalendarEvent> eventsForDateKey(String dateKey) {
    return _calendarEvents
        .where((e) => e.dateKey == dateKey)
        .toList(growable: false);
  }

  bool hasEventsForDateKey(String dateKey) {
    for (final e in _calendarEvents) {
      if (e.dateKey == dateKey) return true;
    }
    return false;
  }

  Future<void> upsertCalendarEvent(CalendarEvent event) async {
    final idx = _calendarEvents.indexWhere((e) => e.id == event.id);
    final next = [..._calendarEvents];
    if (idx >= 0) {
      next[idx] = event;
    } else {
      next.insert(0, event);
    }
    _calendarEvents = next;
    await _storage.saveCalendarEvents(_calendarEvents);
    notifyListeners();
  }

  Future<void> deleteCalendarEvent(String id) async {
    final next = _calendarEvents.where((e) => e.id != id).toList(growable: false);
    _calendarEvents = next;
    await _storage.saveCalendarEvents(_calendarEvents);
    notifyListeners();
  }
}

