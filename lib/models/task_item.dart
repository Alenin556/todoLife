class TaskItem {
  const TaskItem({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAtMs,
  });

  final String id;
  final String text;
  final bool done;
  final int createdAtMs;

  TaskItem copyWith({String? text, bool? done}) {
    return TaskItem(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'createdAtMs': createdAtMs,
      };

  static TaskItem fromJson(Map<String, Object?> j) {
    return TaskItem(
      id: (j['id'] as String?) ?? '',
      text: (j['text'] as String?) ?? '',
      done: (j['done'] as bool?) ?? false,
      createdAtMs: (j['createdAtMs'] as int?) ?? 0,
    );
  }
}

