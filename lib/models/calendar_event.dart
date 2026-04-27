class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.dateKey,
    this.startTime,
    this.endTime,
    this.note,
    this.reminderMinutes,
    this.sourceType,
    this.sourceId,
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
  /// Optional: where event came from (e.g. 'task').
  final String? sourceType;
  /// Optional: id in source domain.
  final String? sourceId;
  final int createdAtMs;

  Map<String, Object?> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
        'reminderMinutes': reminderMinutes,
        'sourceType': sourceType,
        'sourceId': sourceId,
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
      sourceType: j['sourceType'] as String?,
      sourceId: j['sourceId'] as String?,
      createdAtMs: (j['createdAtMs'] as int?) ?? 0,
    );
  }
}

