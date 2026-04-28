import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_event.dart';
import '../models/task_item.dart';

class NotificationsService {
  NotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<NotificationsService> createAndInit() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final svc = NotificationsService(plugin);
    await svc.init();
    return svc;
  }

  Future<void> init() async {
    // Timezone init for scheduled notifications.
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC; better than crashing.
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (r) async {
        // Close action for summary notification.
        if (r.actionId == 'next' && r.id != null) {
          await _plugin.cancel(id: r.id!);
        }
      },
    );

    // Android 13+ runtime permission.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> showDailyTasksSummary({
    required DateTime day,
    required List<TaskItem> tasks,
  }) async {
    if (kIsWeb) return;
    if (tasks.isEmpty) return;

    final dateKey =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final id = _stableId('daily_summary:$dateKey');

    final lines = tasks
        .where((t) => t.text.trim().isNotEmpty)
        .take(7)
        .map((t) => '• ${t.text.trim()}')
        .toList(growable: false);
    final extra = tasks.length - lines.length;
    final body = [
      ...lines,
      if (extra > 0) '…и ещё $extra',
    ].join('\n');

    final androidDetails = AndroidNotificationDetails(
      'daily_tasks_summary',
      'Daily tasks summary',
      channelDescription: 'Daily summary shown on first app open per day',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: const [
        AndroidNotificationAction(
          'next',
          'Далее',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: id,
      title: 'Задачи на сегодня',
      body: body,
      notificationDetails: details,
      payload: dateKey,
    );
  }

  Future<void> scheduleOrUpdateForCalendarEvent(CalendarEvent e) async {
    if (kIsWeb) return;
    final scheduled = _scheduledDateTime(e);
    if (scheduled == null) {
      await cancelForEventId(e.id);
      return;
    }
    if (scheduled.isBefore(DateTime.now())) {
      // Don't fire stale reminders.
      await cancelForEventId(e.id);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'calendar_events',
      'Calendar events',
      channelDescription: 'Notifications for scheduled calendar events',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);
    final id = _stableId(e.id);

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: e.title,
      body: '${e.dateKey} ${e.startTime}',
    );
  }

  Future<void> cancelForEventId(String eventId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _stableId(eventId));
  }

  DateTime? _scheduledDateTime(CalendarEvent e) {
    final t = e.startTime;
    if (t == null || t.trim().isEmpty) return null;
    final reminder = e.reminderMinutes;
    if (reminder == null) return null; // "Без напоминания"
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final dParts = e.dateKey.split('-');
    if (dParts.length != 3) return null;
    final y = int.tryParse(dParts[0]);
    final mo = int.tryParse(dParts[1]);
    final da = int.tryParse(dParts[2]);
    if (y == null || mo == null || da == null) return null;
    final start = DateTime(y, mo, da, h, m);
    return start.subtract(Duration(minutes: reminder));
  }

  int _stableId(String s) {
    // FNV-1a 32-bit
    var hash = 0x811C9DC5;
    for (final cu in s.codeUnits) {
      hash ^= cu;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

