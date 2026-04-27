import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../formatters/thousands_separator_input_formatter.dart';

class SavingsPlanResult {
  const SavingsPlanResult({
    required this.monthlyPayment,
    this.message,
  });

  final double monthlyPayment;
  final String? message;
}

SavingsPlanResult? computeSavingsPlan({
  required double goal,
  required double already,
  required int months,
  required double annualRatePercent,
}) {
  if (goal <= 0 || months <= 0) return null;
  if (already < 0) return null;
  if (annualRatePercent < 0) return null;

  if (already >= goal) {
    return const SavingsPlanResult(
      monthlyPayment: 0,
      message: 'Накопления уже не ниже цели — можно настроить новую.',
    );
  }

  if (annualRatePercent == 0) {
    final p = (goal - already) / months;
    return SavingsPlanResult(
      monthlyPayment: p > 0 ? p : 0,
      message: p <= 0
          ? 'При нулевой ставке цель недостижима с текущими вводами.'
          : null,
    );
  }

  final rM = math.pow(1.0 + annualRatePercent / 100.0, 1.0 / 12.0) - 1.0;
  final n = months.toDouble();
  final fv0 = already * math.pow(1.0 + rM, n).toDouble();
  if (goal <= fv0) {
    return const SavingsPlanResult(
      monthlyPayment: 0,
      message: 'С учётом доходности и текущей суммы цель покрывается без ежемесячных взносов.',
    );
  }
  final oneRn = math.pow(1.0 + rM, n).toDouble();
  final denom = oneRn - 1.0;
  if (denom <= 0) return null;
  final p = (goal - fv0) * rM / denom;
  if (p < 0) {
    return const SavingsPlanResult(
      monthlyPayment: 0,
      message: 'Проверьте введённые данные: получился отрицательный взнос.',
    );
  }
  return SavingsPlanResult(monthlyPayment: p, message: null);
}

class SavingsPlanScreen extends StatefulWidget {
  const SavingsPlanScreen({super.key});

  @override
  State<SavingsPlanScreen> createState() => _SavingsPlanScreenState();
}

class _SavingsPlanScreenState extends State<SavingsPlanScreen> {
  final _goal = TextEditingController();
  final _already = TextEditingController();
  final _months = TextEditingController();
  final _rate = TextEditingController();
  final _money = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void dispose() {
    _goal.dispose();
    _already.dispose();
    _months.dispose();
    _rate.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final normalized = s
        .replaceAll(RegExp(r'[\s\u00A0]'), '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }

  int _parseInt(String s) {
    final n = int.tryParse(s.replaceAll(RegExp(r'[\s\u00A0]'), '').trim());
    return n ?? 0;
  }

  String _fmt(double v) => _money.format(v);

  @override
  Widget build(BuildContext context) {
    final goal = _parse(_goal.text);
    final already = _parse(_already.text);
    final months = _parseInt(_months.text);
    final rate = _parse(_rate.text);
    final res = (goal > 0 && months > 0)
        ? computeSavingsPlan(
            goal: goal,
            already: already,
            months: months,
            annualRatePercent: rate,
          )
        : null;
    return SafeArea(
      child: ListView(
        key: const PageStorageKey('savings_plan_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'План вкладов',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Сколько ежемесячно откладывать, чтобы к сроку накопить цель, '
            'с учётом текущей суммы и ожидаемой годовой доходности. '
            'Взносы в конце месяца, капитализация — ежемесячно.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\s\u00A0\.,]'),
              ),
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Цель, ₽',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _already,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\s\u00A0\.,]'),
              ),
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Уже накоплено, ₽',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _months,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Срок, месяцев',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
            decoration: const InputDecoration(
              labelText: 'Ожидаемая доходность, % годовых (0 — без роста)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (res != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (res.message != null) ...[
                      Text(res.message!),
                    ] else ...[
                      Text(
                        'Ежемесячный взнос',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_fmt(res.monthlyPayment)} ₽',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
