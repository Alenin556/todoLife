import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../scope/app_state_scope.dart';
import '../calendar/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selected = DateTime.now();

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _startOfWeek(DateTime d) {
    final mondayIndex = (d.weekday + 6) % 7; // Monday=0
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: mondayIndex));
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final selected = DateTime(_selected.year, _selected.month, _selected.day);
    final weekStart = _startOfWeek(selected);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(selected);
    final dayLabel = DateFormat('d MMMM, EEEE', 'ru_RU').format(selected);

    final key = _dateKey(selected);
    final events = appState.eventsForDateKey(key);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/home_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0B0C10), Color(0xFF151826)]
                        : const [Color(0xFFF5EBE0), Color(0xFFE3D5CA)],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.85),
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              _Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Неделя',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CalendarScreen()),
                            );
                          },
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: const Text('Календарь'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final d in weekDays) ...[
                          Expanded(
                            child: _DayChip(
                              date: d,
                              selected: d.year == selected.year &&
                                  d.month == selected.month &&
                                  d.day == selected.day,
                              hasEvents: appState.hasEventsForDateKey(_dateKey(d)),
                              onTap: () => setState(() => _selected = d),
                            ),
                          ),
                          if (d != weekDays.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      Text(
                        'На выбранную дату событий нет.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.85),
                            ),
                      )
                    else
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CalendarDayScreen(date: selected)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'События: ${events.length}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.85),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                events.first.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Открыть день →',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.75),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Glass(
                child: _QuoteCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final wd = DateFormat('EE', 'ru_RU').format(date); // short weekday

    final bg = selected
        ? scheme.primaryContainer.withValues(alpha: isDark ? 0.65 : 0.8)
        : Colors.transparent;
    final border = selected
        ? BorderSide(color: scheme.primary.withValues(alpha: 0.7))
        : BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.9),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              wd,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: hasEvents ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? scheme.surfaceContainerHighest : Colors.white)
                .withValues(alpha: isDark ? 0.55 : 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.8),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Quote {
  const _Quote({required this.text, required this.author, this.year});
  final String text;
  final String author;
  final int? year;
}

class _QuoteCard extends StatefulWidget {
  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  static const _quotes = <_Quote>[
    _Quote(
      text: 'Не экономьте то, что осталось после трат — тратьте то, что осталось после сбережений.',
      author: 'Уоррен Баффет',
    ),
    _Quote(
      text: 'Богат не тот, кто много имеет, а тот, кому мало нужно.',
      author: 'Эпикур',
    ),
    _Quote(
      text: 'Сначала скажи себе, каким ты хочешь быть, и затем делай, что нужно.',
      author: 'Эпиктет',
    ),
    _Quote(
      text: 'Счастье твоей жизни зависит от качества твоих мыслей.',
      author: 'Марк Аврелий',
      year: 180,
    ),
    _Quote(
      text: 'Дисциплина важнее мотивации.',
      author: 'Народная мудрость',
    ),
    _Quote(
      text: 'Успех — это сумма небольших усилий, повторяемых изо дня в день.',
      author: 'Роберт Колльер',
    ),
  ];

  int _i = 0;

  void _next() {
    setState(() => _i = (_i + 1) % _quotes.length);
  }

  @override
  Widget build(BuildContext context) {
    final q = _quotes[_i];
    final authorLine = q.year == null ? q.author : '${q.author}, ${q.year}';

    return GestureDetector(
      onHorizontalDragEnd: (_) => _next(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Мотивация',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _next,
                icon: const Icon(Icons.refresh),
                tooltip: 'Новая цитата',
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey('quote_$_i'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${q.text}”',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  authorLine,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Свайп по карточке — следующая.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

