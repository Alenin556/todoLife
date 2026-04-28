import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'models/task_item.dart';
import 'models/calendar_event.dart';
import 'models/salary_split.dart';
import 'services/user_storage.dart';
import 'services/notifications_service.dart';
import 'services/app_lock_service.dart';
import 'ui/screens/tasks/task_list_screen.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage, {NotificationsService? notifications})
      : _notifications = notifications,
        _appLock = AppLockService(_storage);

  final UserStorage _storage;
  final NotificationsService? _notifications;
  final AppLockService _appLock;

  ThemeMode _themeMode = ThemeMode.light;
  bool _ready = false;
  Locale _locale = const Locale('ru', 'RU');

  List<TaskItem> _dailyTasks = const [];
  List<TaskItem> _longTasks = const [];
  List<CalendarEvent> _calendarEvents = const [];
  SalarySplitDraft _salarySplitDraft =
      const SalarySplitDraft(
        salary: 0,
        percents: {},
        customAmounts: {},
        mode: SalarySplitMode.percent,
        manualAmounts: {},
      );
  List<SalarySplitSaved> _savedSalarySplits = const [];

  AppLockSettings _lockSettings = const AppLockSettings(
    enabled: false,
    autoLockSeconds: 0,
    preventScreenshots: true,
  );

  bool _locked = false;
  DateTime? _lastBackgroundAt;
  bool _showPrivacyOnboarding = false;

  ThemeMode get themeMode => _themeMode;
  bool get ready => _ready;
  Locale get locale => _locale;
  AppLockSettings get lockSettings => _lockSettings;
  bool get locked => _locked;
  bool get showPrivacyOnboarding => _showPrivacyOnboarding;

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
      // New day: переносим незавершённые задачи на сегодня (выполненные убираем).
      final carried =
          _dailyTasks.where((t) => !t.done && t.id.isNotEmpty).toList(growable: false);
      _dailyTasks = carried;
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
    _locale = _storage.loadLanguageCode() == 'en'
        ? const Locale('en', 'US')
        : const Locale('ru', 'RU');
    _lockSettings = _appLock.loadSettings();
    // Lock requires PIN. If no PIN is set, keep app unlocked even if enabled.
    _locked = _lockSettings.enabled && await appLockHasPin();
    _dailyTasks = await _storage.loadTasks(TaskKind.daily);
    _longTasks = await _storage.loadTasks(TaskKind.long);
    _calendarEvents = await _storage.loadCalendarEvents();
    await ensureDailyTasksFresh();
    await _maybeShowDailySummaryOnFirstOpen();
    _salarySplitDraft = await _storage.loadSalarySplitDraft();
    _savedSalarySplits = await _storage.loadSavedSalarySplits();
    // Show onboarding only on mobile platforms.
    _showPrivacyOnboarding = (Platform.isAndroid || Platform.isIOS) &&
        !_storage.loadPrivacyOnboardingShown();
    _ready = true;
    notifyListeners();
  }

  Future<void> dismissPrivacyOnboarding() async {
    _showPrivacyOnboarding = false;
    await _storage.savePrivacyOnboardingShown(true);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    await _storage.saveLanguageCode(code);
    _locale = code == 'en' ? const Locale('en', 'US') : const Locale('ru', 'RU');
    notifyListeners();
  }

  Future<void> updateLockSettings(AppLockSettings s) async {
    final wasEnabled = _lockSettings.enabled;
    _lockSettings = s;
    await _appLock.saveSettings(s);
    // If disabled, also unlock.
    if (!s.enabled) {
      _locked = false;
      _lastBackgroundAt = null;
    } else if (!wasEnabled && s.enabled) {
      // Newly enabled: lock only if PIN exists.
      _locked = await appLockHasPin();
      _lastBackgroundAt = null;
    }
    notifyListeners();
  }

  Future<bool> appLockHasPin() => _appLock.hasPin();
  Future<void> setAppPin(String pin) => _appLock.setPin(pin);
  Future<void> clearAppPin() => _appLock.clearPin();
  Future<bool> verifyAppPin(String pin) => _appLock.verifyPin(pin);

  void onAppBackgrounded() {
    if (!_lockSettings.enabled) return;
    _lastBackgroundAt = DateTime.now();
    if (_lockSettings.autoLockSeconds == 0) {
      // Only lock if PIN exists.
      // If user enabled lock without setting PIN, do not brick the app.
      // (They can set PIN later in settings.)
      // ignore: discarded_futures
      appLockHasPin().then((hasPin) {
        if (!hasPin) return;
        _locked = true;
        notifyListeners();
      });
    }
  }

  void onAppResumed() {
    if (!_lockSettings.enabled) return;
    final bg = _lastBackgroundAt;
    // Cold-start locking is handled in init() and when enabling the feature.
    // If we don't have a background timestamp, do not force-lock here
    // (prevents immediately re-locking right after successful unlock).
    if (bg == null) return;
    final elapsed = DateTime.now().difference(bg).inSeconds;
    if (elapsed >= _lockSettings.autoLockSeconds) {
      _locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _locked = false;
    _lastBackgroundAt = null;
    notifyListeners();
  }

  Future<void> _maybeShowDailySummaryOnFirstOpen() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastShown = _storage.loadDailySummaryShownDate();
    final lastShownDay = lastShown == null
        ? null
        : DateTime(lastShown.year, lastShown.month, lastShown.day);

    if (lastShownDay != null && !lastShownDay.isBefore(today)) return;

    // Mark as shown for today (even if there are no tasks), so it happens once per day.
    await _storage.saveDailySummaryShownDate(today);
    await _notifications?.showDailyTasksSummary(day: today, tasks: _dailyTasks);
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
    if (kind == TaskKind.long) {
      await _deleteCalendarEventsForTask(id);
    }
    final updated =
        tasks(kind).where((t) => t.id != id).toList(growable: false);
    await _setTasks(kind, updated);
  }

  Future<void> clearTasks(TaskKind kind) async {
    if (kind == TaskKind.long) {
      // Remove calendar events bound to long-term tasks.
      final ids = tasks(kind).map((t) => t.id).toList(growable: false);
      for (final id in ids) {
        await _deleteCalendarEventsForTask(id);
      }
    }
    await _setTasks(kind, const []);
  }

  Future<void> upsertTask(TaskKind kind,
      {String? id, required String text, String? deadlineDateKey}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    final list = tasks(kind);
    final existingIndex = id == null ? -1 : list.indexWhere((t) => t.id == id);
    final updated = [...list];

    TaskItem? nextTask;
    if (existingIndex >= 0) {
      nextTask = updated[existingIndex].copyWith(
        text: normalized,
        deadlineDateKey: deadlineDateKey,
      );
      updated[existingIndex] = nextTask;
    } else {
      final newId = '$now-${normalized.hashCode}';
      nextTask = TaskItem(
        id: newId,
        text: normalized,
        done: false,
        createdAtMs: now,
        deadlineDateKey: deadlineDateKey,
      );
      updated.insert(0, nextTask);
    }

    await _setTasks(kind, updated);
    if (kind == TaskKind.daily) {
      final now = DateTime.now();
      await _storage.saveDailyTasksDate(DateTime(now.year, now.month, now.day));
    }

    if (kind == TaskKind.long) {
      await _syncLongTaskToCalendar(nextTask);
    }
  }

  Future<void> _syncLongTaskToCalendar(TaskItem task) async {
    // If no deadline, remove bound events.
    if (task.deadlineDateKey == null || task.deadlineDateKey!.trim().isEmpty) {
      await _deleteCalendarEventsForTask(task.id);
      return;
    }

    final eventId = 'task:${task.id}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final event = CalendarEvent(
      id: eventId,
      title: task.text,
      dateKey: task.deadlineDateKey!,
      note: 'Дедлайн долгосрочной задачи',
      sourceType: 'task',
      sourceId: task.id,
      createdAtMs: now,
    );
    await upsertCalendarEvent(event);
  }

  Future<void> _deleteCalendarEventsForTask(String taskId) async {
    final eventId = 'task:$taskId';
    await deleteCalendarEvent(eventId);
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
      mode: _salarySplitDraft.mode,
      manualAmounts: _salarySplitDraft.manualAmounts,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> resetSalarySplitAllocations() async {
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: const {},
      customAmounts: const {},
      mode: SalarySplitMode.percent,
      manualAmounts: const {},
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> setSalarySplitMode(SalarySplitMode mode) async {
    if (_salarySplitDraft.mode == mode) return;
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: _salarySplitDraft.percents,
      customAmounts: _salarySplitDraft.customAmounts,
      mode: mode,
      manualAmounts: _salarySplitDraft.manualAmounts,
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
      mode: _salarySplitDraft.mode,
      manualAmounts: _salarySplitDraft.manualAmounts,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> setSalaryAmount(String category, double amount) async {
    final next = Map<String, double>.from(_salarySplitDraft.manualAmounts);
    if (amount <= 0) {
      next.remove(category);
    } else {
      next[category] = amount;
    }
    _salarySplitDraft = SalarySplitDraft(
      salary: _salarySplitDraft.salary,
      percents: _salarySplitDraft.percents,
      customAmounts: _salarySplitDraft.customAmounts,
      mode: _salarySplitDraft.mode,
      manualAmounts: next,
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
      mode: _salarySplitDraft.mode,
      manualAmounts: _salarySplitDraft.manualAmounts,
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
      mode: _salarySplitDraft.mode,
      manualAmounts: _salarySplitDraft.manualAmounts,
    );
    await _storage.saveSalarySplitDraft(_salarySplitDraft);
    notifyListeners();
  }

  Future<void> deleteSavedSalarySplit(int savedAtMs) async {
    _savedSalarySplits =
        _savedSalarySplits.where((e) => e.savedAtMs != savedAtMs).toList(growable: false);
    await _storage.saveSavedSalarySplits(_savedSalarySplits);
    notifyListeners();
  }

  String exportUserDataJson() {
    // NOTE: should not be sent anywhere automatically. It's for user-controlled export.
    final map = <String, Object?>{
      'version': 1,
      'exportedAtMs': DateTime.now().millisecondsSinceEpoch,
      'dailyTasks': _dailyTasks.map((t) => t.toJson()).toList(),
      'longTasks': _longTasks.map((t) => t.toJson()).toList(),
      'calendarEvents': _calendarEvents.map((e) => e.toJson()).toList(),
      'salarySplitDraft': _salarySplitDraft.toJson(),
      'savedSalarySplits': _savedSalarySplits.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> wipeAllUserData() async {
    await _storage.wipeAllUserData();
    _dailyTasks = const [];
    _longTasks = const [];
    _calendarEvents = const [];
    _salarySplitDraft = const SalarySplitDraft(
      salary: 0,
      percents: {},
      customAmounts: {},
      mode: SalarySplitMode.percent,
      manualAmounts: {},
    );
    _savedSalarySplits = const [];
    _ready = true;
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
    // Android notification: only if startTime exists.
    await _notifications?.scheduleOrUpdateForCalendarEvent(event);
    notifyListeners();
  }

  Future<void> deleteCalendarEvent(String id) async {
    final next = _calendarEvents.where((e) => e.id != id).toList(growable: false);
    _calendarEvents = next;
    await _storage.saveCalendarEvents(_calendarEvents);
    await _notifications?.cancelForEventId(id);
    notifyListeners();
  }
}

