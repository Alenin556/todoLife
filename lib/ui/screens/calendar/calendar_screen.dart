import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      child: Column(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
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
          ),
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
      }
    }
    _initialized = true;
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
                  startTime: null,
                  endTime: null,
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

