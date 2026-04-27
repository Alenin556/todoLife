import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:math';

import '../../../models/calendar_event.dart';
import '../../scope/app_state_scope.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(_month);

    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = (first.weekday + 6) % 7; // Monday=0
    final totalCells = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                _Weekday('Пн'),
                _Weekday('Вт'),
                _Weekday('Ср'),
                _Weekday('Чт'),
                _Weekday('Пт'),
                _Weekday('Сб'),
                _Weekday('Вс'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: totalCells,
              itemBuilder: (context, i) {
                final dayIndex = i - startWeekday + 1;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final d = DateTime(_month.year, _month.month, dayIndex);
                final key = _dateKey(d);
                final hasEvents = appState.hasEventsForDateKey(key);
                final isToday = DateTime.now().year == d.year &&
                    DateTime.now().month == d.month &&
                    DateTime.now().day == d.day;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CalendarDayScreen(date: d),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                      color: hasEvents
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayIndex',
                      style: TextStyle(
                        fontWeight: hasEvents ? FontWeight.w700 : FontWeight.w500,
                        color: hasEvents
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class CalendarDayScreen extends StatelessWidget {
  const CalendarDayScreen({super.key, required this.date});
  final DateTime date;

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final key = _dateKey(date);
    final events = appState.eventsForDateKey(key);
    final title = DateFormat('d MMMM, EEEE', 'ru_RU').format(date);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CalendarEventEditScreen(date: date),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: events.isEmpty
            ? const Center(child: Text('Событий нет. Нажмите + чтобы добавить.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                itemBuilder: (context, i) {
                  final e = events[i];
                  final time = [
                    if (e.startTime != null) e.startTime,
                    if (e.endTime != null) e.endTime,
                  ].whereType<String>().join('–');
                  return Card(
                    child: ListTile(
                      title: Text(e.title),
                      subtitle: Text(
                        [
                          if (time.isNotEmpty) time,
                          if ((e.note ?? '').trim().isNotEmpty) e.note!.trim(),
                        ].join('\n'),
                      ),
                      isThreeLine: (e.note ?? '').trim().isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => appState.deleteCalendarEvent(e.id),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CalendarEventEditScreen(
                              date: date,
                              eventId: e.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class CalendarEventEditScreen extends StatefulWidget {
  const CalendarEventEditScreen({super.key, required this.date, this.eventId});
  final DateTime date;
  final String? eventId;

  @override
  State<CalendarEventEditScreen> createState() => _CalendarEventEditScreenState();
}

class _CalendarEventEditScreenState extends State<CalendarEventEditScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  TimeOfDay? _start;
  TimeOfDay? _end;
  int? _reminder;
  bool _initialized = false;

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final appState = AppStateScope.of(context);
    if (widget.eventId != null) {
      final key = _dateKey(widget.date);
      final existing = appState
          .eventsForDateKey(key)
          .where((e) => e.id == widget.eventId)
          .cast()
          .toList();
      if (existing.isNotEmpty) {
        final e = existing.first;
        _title.text = e.title;
        _note.text = e.note ?? '';
        _reminder = e.reminderMinutes;
        _start = _parseTime(e.startTime);
        _end = _parseTime(e.endTime);
      }
    }
    _initialized = true;
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<TimeOfDay?> _pickRealisticTime(TimeOfDay? initial) async {
    final init = initial ?? TimeOfDay.now();
    var isPm = init.hour >= 12;
    var hour12 = init.hour % 12;
    if (hour12 == 0) hour12 = 12;
    var minute = (init.minute / 5).round() * 5;
    if (minute == 60) minute = 55;

    final hours = List<int>.generate(12, (i) => i + 1); // 1..12
    final minutes = List<int>.generate(12, (i) => i * 5); // 0..55

    var hourIndex = max(0, hours.indexOf(hour12));
    var minuteIndex = max(0, minutes.indexOf(minute));

    final hCtrl = FixedExtentScrollController(initialItem: hourIndex);
    final mCtrl = FixedExtentScrollController(initialItem: minuteIndex);

    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите время'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            TimeOfDay current() {
              final h12 = hours[hourIndex];
              final mm = minutes[minuteIndex];
              var h24 = h12 % 12;
              if (isPm) h24 += 12;
              return TimeOfDay(hour: h24, minute: mm);
            }

            final v = current();
            final preview =
                '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

            return SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preview,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: ListWheelScrollView.useDelegate(
                            controller: hCtrl,
                            itemExtent: 36,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setLocal(() {
                              hourIndex = i;
                            }),
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index >= hours.length) return null;
                                return Center(
                                  child: Text(
                                    hours[index].toString().padLeft(2, '0'),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: ListWheelScrollView.useDelegate(
                            controller: mCtrl,
                            itemExtent: 36,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setLocal(() {
                              minuteIndex = i;
                            }),
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index >= minutes.length) return null;
                                return Center(
                                  child: Text(
                                    minutes[index].toString().padLeft(2, '0'),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          ChoiceChip(
                            label: const Text('AM'),
                            selected: !isPm,
                            onSelected: (_) => setLocal(() => isPm = false),
                          ),
                          const SizedBox(height: 8),
                          ChoiceChip(
                            label: const Text('PM'),
                            selected: isPm,
                            onSelected: (_) => setLocal(() => isPm = true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final h12 = hours[hourIndex];
              final mm = minutes[minuteIndex];
              var h24 = h12 % 12;
              if (isPm) h24 += 12;
              Navigator.of(context).pop(TimeOfDay(hour: h24, minute: mm));
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isEdit = widget.eventId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Редактирование' : 'Новое событие')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Заметка',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickRealisticTime(_start);
                      if (picked == null) return;
                      setState(() => _start = picked);
                    },
                    child: Text(_start == null ? 'Начало' : _formatTime(_start)!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickRealisticTime(_end ?? _start);
                      if (picked == null) return;
                      setState(() => _end = picked);
                    },
                    child: Text(_end == null ? 'Конец' : _formatTime(_end)!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _reminder,
              items: const [
                DropdownMenuItem(value: null, child: Text('Без напоминания')),
                DropdownMenuItem(value: 5, child: Text('За 5 минут')),
                DropdownMenuItem(value: 15, child: Text('За 15 минут')),
                DropdownMenuItem(value: 30, child: Text('За 30 минут')),
                DropdownMenuItem(value: 60, child: Text('За 60 минут')),
              ],
              onChanged: (v) => setState(() => _reminder = v),
              decoration: const InputDecoration(
                labelText: 'Напоминание',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final title = _title.text.trim();
                if (title.isEmpty) return;
                final now = DateTime.now().millisecondsSinceEpoch;
                final id = widget.eventId ?? '$now-${title.hashCode}';
                final event = CalendarEvent(
                  id: id,
                  title: title,
                  dateKey: _dateKey(widget.date),
                  startTime: _formatTime(_start),
                  endTime: _formatTime(_end),
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                  reminderMinutes: _reminder,
                  createdAtMs: now,
                );
                await appState.upsertCalendarEvent(event);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

