class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.dateKey,
    this.startTime,
    this.endTime,
    this.note,
    this.reminderMinutes,
    required this.createdAtMs,
  });

  final String id;
  /// YYYY-MM-DD
  final String dateKey;
  final String title;
  /// "HH:mm" or null
  final String? startTime;
  /// "HH:mm" or null
  final String? endTime;
  final String? note;
  /// Minutes before start, optional
  final int? reminderMinutes;
  final int createdAtMs;

  Map<String, Object?> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
        'reminderMinutes': reminderMinutes,
        'createdAtMs': createdAtMs,
      };

  static CalendarEvent fromJson(Map<String, Object?> j) {
    return CalendarEvent(
      id: (j['id'] as String?) ?? '',
      dateKey: (j['dateKey'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      startTime: j['startTime'] as String?,
      endTime: j['endTime'] as String?,
      note: j['note'] as String?,
      reminderMinutes: (j['reminderMinutes'] as num?)?.toInt(),
      createdAtMs: (j['createdAtMs'] as int?) ?? 0,
    );
  }
}

