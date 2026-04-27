import 'package:flutter/material.dart';

class QuotesHomeScreen extends StatefulWidget {
  const QuotesHomeScreen({super.key});

  @override
  State<QuotesHomeScreen> createState() => _QuotesHomeScreenState();
}

class _Quote {
  const _Quote({required this.text, required this.author});

  final String text;
  final String author;
}

class _QuotesHomeScreenState extends State<QuotesHomeScreen> {
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
      text: 'Дисциплина важнее мотивации.',
      author: 'Народная мудрость',
    ),
    _Quote(
      text: 'Успех — это сумма небольших усилий, повторяемых изо дня в день.',
      author: 'Роберт Колльер',
    ),
  ];

  static String? _authorLineForUi(_Quote q) {
    final a = q.author.toLowerCase();
    if (a == 'народная мудрость' || a == 'todolife') return null;
    return q.author;
  }

  int _i = 0;

  void _next() {
    setState(() {
      _i = (_i + 1) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _quotes[_i];
    final authorLine = _authorLineForUi(q);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GestureDetector(
              onHorizontalDragEnd: (_) => _next(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Card(
                      key: ValueKey('quote_$_i'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“${q.text}”',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (authorLine != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                authorLine,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _next,
                    child: const Text('Новая цитата'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Совет: свайпните влево/вправо по карточке.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

