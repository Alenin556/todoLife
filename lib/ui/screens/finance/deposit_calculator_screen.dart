import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/deposit_calc.dart';
import '../../formatters/thousands_separator_input_formatter.dart';

class DepositCalculatorScreen extends StatefulWidget {
  const DepositCalculatorScreen({super.key});

  @override
  State<DepositCalculatorScreen> createState() => _DepositCalculatorScreenState();
}

class _DepositCalculatorScreenState extends State<DepositCalculatorScreen> {
  final _p = TextEditingController();
  final _r = TextEditingController();
  final _t = TextEditingController();

  DepositTermUnit _unit = DepositTermUnit.months;
  final _money = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void dispose() {
    _p.dispose();
    _r.dispose();
    _t.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final normalized = s
        .replaceAll(RegExp(r'[\s\u00A0]'), '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }
  String _fmtMoney(double v) => _money.format(v);

  @override
  Widget build(BuildContext context) {
    final principal = _parse(_p.text);
    final rate = _parse(_r.text);
    final term = _parse(_t.text);
    final input = DepositInput(
      principal: principal,
      ratePercentPerYear: rate,
      termValue: term,
      termUnit: _unit,
      compoundsPerYear: 12,
    );
    final res = calculateDeposit(input);
    final error = (principal < 0 || rate < 0 || term < 0)
        ? 'Значения не могут быть отрицательными.'
        : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Депозитный калькулятор',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _p,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\\s\\u00A0\\.,]'),
              ),
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Сумма вклада',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _r,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\\.,]'))],
            decoration: const InputDecoration(
              labelText: 'Ставка, % годовых',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _t,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\\.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Срок',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<DepositTermUnit>(
                value: _unit,
                items: const [
                  DropdownMenuItem(
                    value: DepositTermUnit.months,
                    child: Text('мес'),
                  ),
                  DropdownMenuItem(
                    value: DepositTermUnit.years,
                    child: Text('лет'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _unit = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Итоговая сумма: ${_fmtMoney(res.total)}'),
                  const SizedBox(height: 8),
                  Text('Чистая прибыль: ${_fmtMoney(res.profit)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Капитализация: 12 раз в год',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

