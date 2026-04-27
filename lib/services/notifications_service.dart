import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_event.dart';

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
    await _plugin.initialize(settings: initSettings);

    // Android 13+ runtime permission.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> scheduleOrUpdateForCalendarEvent(CalendarEvent e) async {
    if (kIsWeb) return;
    final start = _eventStartDateTime(e);
    if (start == null) {
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
      scheduledDate: tz.TZDateTime.from(start, tz.local),
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

  DateTime? _eventStartDateTime(CalendarEvent e) {
    final t = e.startTime;
    if (t == null || t.trim().isEmpty) return null;
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
    return DateTime(y, mo, da, h, m);
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

