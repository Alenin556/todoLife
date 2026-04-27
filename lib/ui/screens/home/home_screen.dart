import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../scope/app_state_scope.dart';
import '../calendar/calendar_screen.dart';
import '../tasks/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selected = DateTime.now();
  Timer? _quoteTimer;
  int _quoteIndex = 0;

  static const _quotes = <({String text, String author})>[
    (
      text:
          'Не экономьте то, что осталось после трат — тратьте то, что осталось после сбережений.',
      author: 'Уоррен Баффет',
    ),
    (
      text: 'Богат не тот, кто много имеет, а тот, кому мало нужно.',
      author: 'Эпикур',
    ),
    (
      text: 'Сначала скажи себе, каким ты хочешь быть, и затем делай, что нужно.',
      author: 'Эпиктет',
    ),
    (
      text: 'Счастье твоей жизни зависит от качества твоих мыслей.',
      author: 'Марк Аврелий',
    ),
    (
      text: 'Дисциплина важнее мотивации.',
      author: 'Народная мудрость',
    ),
    (
      text: 'Успех — это сумма небольших усилий, повторяемых изо дня в день.',
      author: 'Роберт Колльер',
    ),
  ];

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _nextQuote();
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final mondayIndex = (day.weekday + 6) % 7; // Monday=0
    return day.subtract(Duration(days: mondayIndex));
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // (Intentionally unused for now) Keep today key available for future Home widgets.
    // ignore: unused_local_variable
    final daily = appState.tasks(TaskKind.daily);
    // ignore: unused_local_variable
    final dailyLeft = daily.where((t) => t.done == false).toList(growable: false);
    // ignore: unused_local_variable
    final eventsList = appState.eventsForDateKey(dateKey);
    final topTitle = 'TODO LIFE';
    final topSubtitle = 'ПЛАН И ДИСЦИПЛИНА';

    final selected = DateTime(_selected.year, _selected.month, _selected.day);
    final weekStart = _startOfWeek(selected);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final selectedKey = _dateKey(selected);
    final selectedEvents = appState.eventsForDateKey(selectedKey);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/home_bg.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xC8000000),
                  Color(0x8A000000),
                  Color(0x66000000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep spacing consistent across screens.

                return Stack(
                  children: [
                    // (Removed) left vertical label per request.

                    // Top-left title block
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 2.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // (Removed) Big metric + mode buttons per request.

                    // Motivation quote (auto-rotate every 30s)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 110,
                      bottom: 210,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _QuoteView(
                              key: ValueKey('quote_$_quoteIndex'),
                              text: _quotes[_quoteIndex].text,
                              author: _quotes[_quoteIndex].author,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom: calendar strip + events summary
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _BottomCalendar(
                        today: today,
                        selected: selected,
                        weekDays: weekDays,
                        hasEvents: (d) => appState.hasEventsForDateKey(_dateKey(d)),
                        onSelect: (d) => setState(() => _selected = d),
                        events: selectedEvents,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteView extends StatelessWidget {
  const _QuoteView({super.key, required this.text, required this.author});

  final String text;
  final String author;

  @override
  Widget build(BuildContext context) {
    // Keep layout robust for small heights (e.g. tests / web resize).
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 140;
        final quoteSize = compact ? 18.0 : 22.0;
        final quoteLines = compact ? 3 : 4;
        final authorSize = compact ? 9.0 : 10.0;
        final gap = compact ? 6.0 : 10.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“$text”',
              maxLines: quoteLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: quoteSize,
                height: 1.16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: gap),
            Text(
              author.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: authorSize,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomCalendar extends StatelessWidget {
  const _BottomCalendar({
    required this.today,
    required this.selected,
    required this.weekDays,
    required this.hasEvents,
    required this.onSelect,
    required this.events,
  });

  final DateTime today;
  final DateTime selected;
  final List<DateTime> weekDays;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onSelect;
  final List<dynamic> events; // CalendarEvent, but avoid import cycle here.

  @override
  Widget build(BuildContext context) {
    final dateText =
        DateFormat('d MMMM yyyy', 'ru_RU').format(selected).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
              letterSpacing: 2.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in weekDays) ...[
                Expanded(
                  child: _MiniDay(
                    date: d,
                    isToday: d.year == today.year &&
                        d.month == today.month &&
                        d.day == today.day,
                    selected: d.year == selected.year &&
                        d.month == selected.month &&
                        d.day == selected.day,
                    hasEvents: hasEvents(d),
                    onTap: () => onSelect(d),
                  ),
                ),
                if (d != weekDays.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (events.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Open day details via existing CalendarDayScreen.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalendarDayScreen(date: selected),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СОБЫТИЙ: ${events.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 9,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (events.first as dynamic).title.toString().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 9,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Text(
                'СОБЫТИЙ НЕТ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniDay extends StatelessWidget {
  const _MiniDay({
    required this.date,
    required this.isToday,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.22);
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: selected ? 1.2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EE', 'ru_RU').format(date).toUpperCase(),
              style: TextStyle(
                color: fg,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: fg,
                fontSize: 13,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: hasEvents
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                height: 1,
                width: 16,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

