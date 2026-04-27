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
  DateTime _weekAnchor = DateTime.now(); // Monday of visible week
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
    (text: 'Начни с малого — но начни сегодня.', author: 'todoLife'),
    (text: 'Делай важное первым.', author: 'todoLife'),
    (text: 'Системы побеждают настроение.', author: 'todoLife'),
    (text: 'Планируй, чтобы жить легче.', author: 'todoLife'),
    (text: 'Не жди идеального момента — создай его.', author: 'todoLife'),
    (text: 'Один шаг в день — это тоже путь.', author: 'todoLife'),
    (text: 'Дисциплина — это забота о будущем себе.', author: 'todoLife'),
    (text: 'Стабильность сильнее рывков.', author: 'todoLife'),
    (text: 'Побеждает тот, кто возвращается к делу.', author: 'todoLife'),
    (text: 'Маленькие привычки строят большие результаты.', author: 'todoLife'),
    (text: 'Доводи до конца хотя бы одну вещь.', author: 'todoLife'),
    (text: 'Сделай проще. Сделай сейчас.', author: 'todoLife'),
    (text: 'День — это единица победы.', author: 'todoLife'),
    (text: 'Фокус — это умение говорить «нет».', author: 'Стив Джобс'),
    (text: 'Будущее зависит от того, что ты делаешь сегодня.', author: 'Махатма Ганди'),
    (text: 'Сложные цели состоят из простых действий.', author: 'todoLife'),
    (text: 'Сначала порядок — потом скорость.', author: 'todoLife'),
    (text: 'Стабильно — значит надёжно.', author: 'todoLife'),
    (text: 'Действуй так, будто мотивация уже пришла.', author: 'todoLife'),
    (text: 'Не сравнивай. Улучшай.', author: 'todoLife'),
    (text: 'Сделано — лучше, чем идеально.', author: 'Народная мудрость'),
    (text: 'Сила в привычке.', author: 'todoLife'),
    (text: 'Управляй временем, а не настроение — собой.', author: 'todoLife'),
    (text: 'Каждый чек-лист — это ясность.', author: 'todoLife'),
    (text: 'Сначала здоровье, затем задачи.', author: 'todoLife'),
    (text: 'Тишина — это тоже прогресс.', author: 'todoLife'),
    (text: 'Не усложняй то, что можно выполнить.', author: 'todoLife'),
    (text: 'Задачи на бумаге — меньше тревоги в голове.', author: 'todoLife'),
    (text: 'Отдых — часть дисциплины.', author: 'todoLife'),
    (text: 'Делай по чуть-чуть, но каждый день.', author: 'todoLife'),
    (text: 'Накопление — это стратегия, не жертва.', author: 'todoLife'),
    (text: 'Бюджет — это свобода, а не ограничения.', author: 'todoLife'),
    (text: 'Твои деньги должны работать на тебя.', author: 'todoLife'),
    (text: 'Сначала заплати себе.', author: 'Народная мудрость'),
    (text: 'Контроль начинается с учёта.', author: 'todoLife'),
    (text: 'Считай — и увидишь рост.', author: 'todoLife'),
    (text: 'Простые правила побеждают сложные планы.', author: 'todoLife'),
    (text: 'Рутина — это форма силы.', author: 'todoLife'),
    (text: 'Ничего не меняется, если ничего не менять.', author: 'todoLife'),
    (text: 'Сделай сегодня то, за что завтра скажешь спасибо.', author: 'todoLife'),
    (text: 'Важное редко бывает срочным.', author: 'Дуайт Эйзенхауэр'),
    (text: 'Вдохновение приходит в процессе.', author: 'todoLife'),
    (text: 'Сконцентрируйся на следующем шаге.', author: 'todoLife'),
    (text: 'Ты — это то, что ты повторяешь.', author: 'Аристотель'),
    (text: 'Каждая задача — кирпич в твоём будущем.', author: 'todoLife'),
    (text: 'Упорядочи день — и появится энергия.', author: 'todoLife'),
    (text: 'Сделай минимум — и это уже победа.', author: 'todoLife'),
    (text: 'Пять минут — тоже время.', author: 'todoLife'),
    (text: 'Стабильный темп — лучший темп.', author: 'todoLife'),
    (text: 'Сомнение не делает дело.', author: 'todoLife'),
    (text: 'План без действия — просто желание.', author: 'todoLife'),
    (text: 'Действие лечит страх.', author: 'todoLife'),
    (text: 'Лучший тайм-менеджмент — приоритеты.', author: 'todoLife'),
    (text: 'Сначала главное — потом остальное.', author: 'todoLife'),
    (text: 'Окружай себя ясностью.', author: 'todoLife'),
    (text: 'Не откладывай лёгкое: оно становится тяжёлым.', author: 'todoLife'),
    (text: 'Сделай один звонок. Напиши одно сообщение. Сдвинь дело.', author: 'todoLife'),
    (text: 'Твоя цель любит регулярность.', author: 'todoLife'),
    (text: 'Меньше шума — больше результата.', author: 'todoLife'),
    (text: 'Сосредоточься на том, что можешь контролировать.', author: 'todoLife'),
    (text: 'Дисциплина — это выбор.', author: 'todoLife'),
    (text: 'Отмечай выполненное — мозг любит прогресс.', author: 'todoLife'),
    (text: 'Список дел — это карта, а не приговор.', author: 'todoLife'),
    (text: 'Если устал — замедлись, но не останавливайся.', author: 'todoLife'),
    (text: 'День без плана — день на автопилоте.', author: 'todoLife'),
    (text: 'Чистая голова начинается с чистого списка.', author: 'todoLife'),
    (text: 'Твоя дисциплина — твоя опора.', author: 'todoLife'),
    (text: 'Сначала постоянство, потом скорость.', author: 'todoLife'),
    (text: 'Сделай один маленький шаг прямо сейчас.', author: 'todoLife'),
    (text: 'Побеждает тот, кто не сдаётся на простом.', author: 'todoLife'),
    (text: 'Умение заканчивать — суперсила.', author: 'todoLife'),
    (text: 'Долгосрочно выигрывает терпеливый.', author: 'todoLife'),
    (text: 'Сначала фундамент, потом вершины.', author: 'todoLife'),
    (text: 'Сократи до сущности.', author: 'todoLife'),
    (text: 'Решение — это действие.', author: 'todoLife'),
    (text: 'Сделай сегодня на 1% лучше.', author: 'todoLife'),
    (text: 'Сильные привычки — тихие привычки.', author: 'todoLife'),
    (text: 'Записывай: память любит подводить.', author: 'todoLife'),
    (text: 'Время — твой главный актив.', author: 'todoLife'),
    (text: 'Свобода — это порядок в делах и деньгах.', author: 'todoLife'),
    (text: 'Если задача пугает — разбей её.', author: 'todoLife'),
    (text: 'Минимум действий > максимум размышлений.', author: 'todoLife'),
    (text: 'Дедлайн — это форма заботы о результате.', author: 'todoLife'),
    (text: 'Уважай своё время: ставь границы.', author: 'todoLife'),
    (text: 'Не нужно всё успеть — нужно успеть важное.', author: 'todoLife'),
    (text: 'Один список. Один день. Один шаг.', author: 'todoLife'),
    (text: 'Сначала ясность, потом мотивация.', author: 'todoLife'),
    (text: 'Проверяй план утром, благодарь себя вечером.', author: 'todoLife'),
    (text: 'Твои действия — твой характер.', author: 'todoLife'),
    (text: 'Привычка экономить — привычка побеждать.', author: 'todoLife'),
    (text: 'Сбережения — это уважение к будущему.', author: 'todoLife'),
    (text: 'Где внимание — там рост.', author: 'todoLife'),
    (text: 'Порядок — это роскошь, доступная каждому.', author: 'todoLife'),
    (text: 'Будь верен процессу.', author: 'todoLife'),
    (text: 'Путь строится шагами.', author: 'todoLife'),
    (text: 'Работай с тем, что есть — и станет больше.', author: 'todoLife'),
  ];

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selected = today;
    _weekAnchor = _startOfWeek(today);
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
    final weekStart = _startOfWeek(_weekAnchor);
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
                        onSelect: (d) async {
                          setState(() {
                            _selected = d;
                            _weekAnchor = _startOfWeek(d);
                          });
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CalendarEventEditScreen(date: d),
                            ),
                          );
                        },
                        onPrevWeek: () => setState(() {
                          _weekAnchor = _weekAnchor.subtract(const Duration(days: 7));
                        }),
                        onNextWeek: () => setState(() {
                          _weekAnchor = _weekAnchor.add(const Duration(days: 7));
                        }),
                        onToday: () => setState(() {
                          _selected = today;
                          _weekAnchor = _startOfWeek(today);
                        }),
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
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.events,
  });

  final DateTime today;
  final DateTime selected;
  final List<DateTime> weekDays;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
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
          Row(
            children: [
              IconButton(
                onPressed: onPrevWeek,
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Expanded(
                child: Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 11,
                    letterSpacing: 2.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToday,
                child: Text(
                  'СЕГОДНЯ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 120) return;
              if (v > 0) {
                onPrevWeek();
              } else {
                onNextWeek();
              }
            },
            child: Row(
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

