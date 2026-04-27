import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/salary_split.dart';
import '../../formatters/thousands_separator_input_formatter.dart';
import '../../scope/app_state_scope.dart';

class SalarySplitScreen extends StatefulWidget {
  const SalarySplitScreen({super.key});

  @override
  State<SalarySplitScreen> createState() => _SalarySplitScreenState();
}

class _SalarySplitScreenState extends State<SalarySplitScreen> {
  TextEditingController? _salary;
  bool _initialized = false;
  bool _confirmed = false;
  final _money = NumberFormat('#,##0', 'ru_RU');
  final Map<String, TextEditingController> _amountCtrls = {};

  static const _required = <String>[
    'Кредиты',
    'Инвестиции',
    'Долги',
    'Кошелек',
  ];

  static const _optional = <String>[
    'Покупки',
    'Еда',
    'КВ',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final appState = AppStateScope.of(context);
    final draft = appState.salarySplitDraft;
    _salary = TextEditingController(
      text: draft.salary == 0 ? '' : _fmt(draft.salary),
    );
    _confirmed = draft.salary > 0;
    _initialized = true;
  }

  @override
  void dispose() {
    _salary?.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String s) {
    final normalized = s
        .replaceAll(RegExp(r'[\s\u00A0\u202F\u2009]'), '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }

  String _fmt(double v) => _money.format(v);

  List<int> get _percentOptions => const [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];

  int _totalPercent(Map<String, int> percents) =>
      percents.values.fold<int>(0, (a, b) => a + b);

  double _amount(double salary, int percent) => salary * percent / 100.0;

  Map<String, double> _customExceedings({
    required double salary,
    required double allocatedByPercents,
    required Map<String, double> customAmounts,
  }) {
    var remaining = salary - allocatedByPercents;
    final exceedings = <String, double>{};
    for (final e in customAmounts.entries) {
      remaining -= e.value;
      if (remaining < 0) {
        exceedings[e.key] = remaining.abs();
      }
    }
    return exceedings;
  }

  Future<void> _confirmSalary(double salary) async {
    final appState = AppStateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить сумму?'),
        content: Text('ЗП: ${_fmt(salary)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Изменить'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await appState.setSalary(salary);
    if (!mounted) return;
    setState(() => _confirmed = true);
  }

  TextEditingController _amountCtrl(String category, double amount) {
    return _amountCtrls.putIfAbsent(
      category,
      () => TextEditingController(text: amount <= 0 ? '' : _fmt(amount)),
    );
  }

  Future<void> _editAmountForCategory({
    required dynamic appState,
    required String category,
    required double currentAmount,
  }) async {
    final c = TextEditingController(text: currentAmount <= 0 ? '' : _fmt(currentAmount));
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сумма: $category'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[0-9\s\u00A0\.,]'),
            ),
            ThousandsSeparatorInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Сумма',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final v = _parse(c.text);
              Navigator.of(context).pop(v);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await appState.setSalarySplitMode(SalarySplitMode.amount);
    await appState.setSalaryAmount(category, amount);
    final ctrl = _amountCtrl(category, amount);
    ctrl.text = amount <= 0 ? '' : _fmt(amount);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final salaryCtrl = _salary;
    if (salaryCtrl == null) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final draft = appState.salarySplitDraft;
    final salary = _parse(salaryCtrl.text);
    final percents = draft.percents;
    final totalPercent = _totalPercent(percents);
    final allocatedByPercents = _amount(draft.salary, totalPercent);
    final customTotal =
        draft.customAmounts.values.fold<double>(0, (a, b) => a + b);
    final manualTotal =
        draft.manualAmounts.values.fold<double>(0, (a, b) => a + b);
    final allocated = draft.mode == SalarySplitMode.amount
        ? manualTotal
        : allocatedByPercents;
    final diff = draft.salary - allocated - customTotal;
    final exceedings = _customExceedings(
      salary: draft.salary,
      allocatedByPercents: allocated,
      customAmounts: draft.customAmounts,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Распределение ЗП',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\s\u00A0\.,]'),
              ),
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Зарплата (ЗП)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {
                if (_confirmed) _confirmed = false;
              });
            },
          ),
          const SizedBox(height: 8),
          if (!_confirmed) ...[
            FilledButton(
              onPressed: salary > 0 ? () => _confirmSalary(salary) : null,
              child: const Text('Подтвердить сумму'),
            ),
            const SizedBox(height: 8),
            Text(
              'После подтверждения появятся параметры распределения.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            SegmentedButton<SalarySplitMode>(
              segments: const [
                ButtonSegment(
                  value: SalarySplitMode.percent,
                  label: Text('%'),
                  icon: Icon(Icons.percent),
                ),
                ButtonSegment(
                  value: SalarySplitMode.amount,
                  label: Text('Суммы'),
                  icon: Icon(Icons.payments_outlined),
                ),
              ],
              selected: {draft.mode},
              onSelectionChanged: (s) => appState.setSalarySplitMode(s.first),
            ),
            const SizedBox(height: 8),
            if (diff > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Есть остаток: ${_fmt(diff)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (draft.mode == SalarySplitMode.percent) ...[
              for (final k in _required) _CategoryPercentRow(
                title: k,
                salary: draft.salary,
                currentPercent: percents[k] ?? 0,
                totalPercent: totalPercent,
                percentOptions: _percentOptions,
                onPick: (p) => appState.setSalaryPercent(k, p),
                onEditAmount: () => _editAmountForCategory(
                  appState: appState,
                  category: k,
                  currentAmount: draft.manualAmounts[k] ?? 0,
                ),
              ),
              const SizedBox(height: 4),
              for (final k in _optional) _CategoryPercentRow(
                title: k,
                salary: draft.salary,
                currentPercent: percents[k] ?? 0,
                totalPercent: totalPercent,
                percentOptions: _percentOptions,
                onPick: (p) => appState.setSalaryPercent(k, p),
                onEditAmount: () => _editAmountForCategory(
                  appState: appState,
                  category: k,
                  currentAmount: draft.manualAmounts[k] ?? 0,
                ),
              ),
            ] else ...[
              _AmountsEditorCard(
                requiredCategories: _required,
                optionalCategories: _optional,
                controllerFor: (cat) => _amountCtrl(cat, draft.manualAmounts[cat] ?? 0),
                onChanged: (cat, v) => appState.setSalaryAmount(cat, v),
                parse: _parse,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final res = await showDialog<_CustomCategoryDraft>(
                    context: context,
                    builder: (context) => _AddCategoryDialog(
                      remaining: (draft.salary - allocated) - customTotal,
                      formatMoney: _fmt,
                    ),
                  );
                  if (res == null) return;
                  await appState.addCustomSalaryCategory(res.name, res.amount);
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить категорию'),
              ),
            ),
            for (final e in draft.customAmounts.entries)
              Card(
                child: ListTile(
                  title: Text(e.key),
                  subtitle: Text(
                    exceedings.containsKey(e.key)
                        ? '${_fmt(e.value)}  (превышение: ${_fmt(exceedings[e.key]!)})'
                        : _fmt(e.value),
                    style: TextStyle(
                      color: exceedings.containsKey(e.key)
                          ? Theme.of(context).colorScheme.error
                          : null,
                      fontWeight: exceedings.containsKey(e.key)
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => appState.deleteCustomSalaryCategory(e.key),
                  ),
                ),
              ),
            if (exceedings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Превышение остатка',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final e in exceedings.entries)
                          Text(
                            '${e.key}: +${_fmt(e.value)}',
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.mode == SalarySplitMode.percent)
                      Text(
                        'Распределено: $totalPercent%  (${_fmt(allocated)})',
                      )
                    else
                      Text('Распределено: ${_fmt(allocated)}'),
                    const SizedBox(height: 8),
                    Text(
                      diff >= 0 ? 'Остаток: ${_fmt(diff)}' : 'Дефицит: ${_fmt(diff.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: diff >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => appState.saveCurrentSalarySplit(),
              child: const Text('Сохранить'),
            ),
          ],
          const SizedBox(height: 16),
          if (appState.savedSalarySplits.isNotEmpty) ...[
            Text(
              'Сохраненные бюджеты',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final r in appState.savedSalarySplits.take(5))
              _SavedBudgetTile(
                savedAtMs: r.savedAtMs,
                salary: r.draft.salary,
                percents: r.draft.percents,
                customAmounts: r.draft.customAmounts,
                formatMoney: _fmt,
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить бюджет?'),
                      content: const Text('Это действие нельзя отменить.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await appState.deleteSavedSalarySplit(r.savedAtMs);
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _SavedBudgetTile extends StatelessWidget {
  const _SavedBudgetTile({
    required this.savedAtMs,
    required this.salary,
    required this.percents,
    required this.customAmounts,
    required this.formatMoney,
    required this.onDelete,
  });

  final int savedAtMs;
  final double salary;
  final Map<String, int> percents;
  final Map<String, double> customAmounts;
  final String Function(double) formatMoney;
  final VoidCallback onDelete;

  double _amount(double salary, int percent) => salary * percent / 100.0;

  @override
  Widget build(BuildContext context) {
    final totalPercent = percents.values.fold<int>(0, (a, b) => a + b);
    final allocated = _amount(salary, totalPercent);
    final customTotal =
        customAmounts.values.fold<double>(0, (a, b) => a + b);
    final diff = salary - allocated - customTotal;

    final entries = percents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ЗП: ${formatMoney(salary)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Распределено: $totalPercent%  (${formatMoney(allocated)})'),
            if (customAmounts.isNotEmpty)
              Text('Пользовательские: ${formatMoney(customTotal)}'),
            if (diff > 0) Text('Остаток: ${formatMoney(diff)}'),
            const SizedBox(height: 8),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${e.key}: ${e.value}%  (${formatMoney(_amount(salary, e.value))})',
                ),
              ),
            for (final e in customAmounts.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${e.key}: ${formatMoney(e.value)}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAmountRow extends StatelessWidget {
  const _CategoryAmountRow({
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.parse,
  });

  final String title;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;
  final double Function(String) parse;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9\s\u00A0\.,]'),
                ),
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => onChanged(parse(s)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountsEditorCard extends StatelessWidget {
  const _AmountsEditorCard({
    required this.requiredCategories,
    required this.optionalCategories,
    required this.controllerFor,
    required this.onChanged,
    required this.parse,
  });

  final List<String> requiredCategories;
  final List<String> optionalCategories;
  final TextEditingController Function(String category) controllerFor;
  final void Function(String category, double value) onChanged;
  final double Function(String) parse;

  @override
  Widget build(BuildContext context) {
    final all = [...requiredCategories, ...optionalCategories];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Суммы по категориям', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            for (final cat in all) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cat,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: controllerFor(cat),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9\s\u00A0\.,]'),
                        ),
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: '₽',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (s) => onChanged(cat, parse(s)),
                    ),
                  ),
                ],
              ),
              if (cat != all.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomCategoryDraft {
  const _CustomCategoryDraft(this.name, this.amount);
  final String name;
  final double amount;
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({
    required this.remaining,
    required this.formatMoney,
  });

  final double remaining;
  final String Function(double) formatMoney;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();

  double _parse(String s) {
    final normalized = s
        .replaceAll(RegExp(r'[\s\u00A0\u202F\u2009]'), '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая категория'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Остаток сейчас: ${widget.formatMoney(widget.remaining)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Сумма',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            final amount = _parse(_amount.text);
            if (name.isEmpty || amount <= 0) return;
            Navigator.of(context).pop(_CustomCategoryDraft(name, amount));
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

class _CategoryPercentRow extends StatelessWidget {
  const _CategoryPercentRow({
    required this.title,
    required this.salary,
    required this.currentPercent,
    required this.totalPercent,
    required this.percentOptions,
    required this.onPick,
    required this.onEditAmount,
  });

  final String title;
  final double salary;
  final int currentPercent;
  final int totalPercent;
  final List<int> percentOptions;
  final ValueChanged<int> onPick;
  final VoidCallback onEditAmount;

  double _amount(double salary, int percent) => salary * percent / 100.0;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ru_RU');
    final baseWithoutThis = totalPercent - currentPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall),
                ),
                InkWell(
                  onTap: onEditAmount,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPercent == 0
                              ? '—'
                              : fmt.format(_amount(salary, currentPercent)),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in percentOptions)
                  ChoiceChip(
                    label: Text(p == 0 ? '0%' : '$p%'),
                    selected: currentPercent == p,
                    onSelected: (selected) {
                      if (!selected) return;
                      // Prevent exceeding 100%.
                      final nextTotal = baseWithoutThis + p;
                      if (nextTotal > 100) return;
                      onPick(p);
                    },
                  ),
              ],
            ),
            if (baseWithoutThis + currentPercent >= 100)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Достигнут лимит 100% — чтобы добавить, уменьшите процент в другой категории.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

