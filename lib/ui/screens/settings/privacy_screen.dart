import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../scope/app_state_scope.dart';
import '../../../services/android_secure_screen.dart';
import '../../../app_state.dart';
import '../tasks/task_list_screen.dart';

enum _DocKind { privacy, terms, consent }

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final lock = appState.lockSettings;
    final isEn = appState.locale.languageCode == 'en';
    final pinStatus = FutureBuilder<bool>(
      future: appState.appLockHasPin(),
      builder: (context, snap) {
        final hasPin = snap.data ?? false;
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(hasPin ? 'PIN-код' : 'Создать PIN-код'),
              subtitle: Text(hasPin ? 'Изменить PIN' : 'Установить PIN для блокировки'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final kind = hasPin ? _PinFlowKind.change : _PinFlowKind.create;
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AppStateScope(
                      notifier: appState,
                      child: _PinFlowScreen(kind: kind),
                    ),
                  ),
                );
                if (!context.mounted) return;
                if (ok == true) {
                  final snack = SnackBar(
                    content: const Text('PIN-код установлен'),
                    action: SnackBarAction(
                      label: 'Далее',
                      onPressed: () {},
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(snack);
                }
              },
            ),
            if (hasPin) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: const Text('Создать новый PIN-код'),
                subtitle: const Text('Потребуется ввести старый PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AppStateScope(
                        notifier: appState,
                        child: const _PinFlowScreen(kind: _PinFlowKind.change),
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  if (ok == true) {
                    final snack = SnackBar(
                      content: const Text('PIN-код обновлён'),
                      action: SnackBarAction(
                        label: 'Далее',
                        onPressed: () {},
                      ),
                    );
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(snack);
                  }
                },
              ),
            ],
          ],
        );
      },
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Конфиденциальность')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(isEn ? 'Privacy Policy' : 'Политика конфиденциальности'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppStateScope(
                          notifier: appState,
                          child: _DocScreen(kind: _DocKind.privacy, isEn: isEn),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(isEn ? 'Terms of Use' : 'Условия использования'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppStateScope(
                          notifier: appState,
                          child: _DocScreen(kind: _DocKind.terms, isEn: isEn),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(isEn ? 'Consent (template)' : 'Согласие (шаблон)'),
                    subtitle: Text(
                      isEn ? 'Needed for analytics/crash reports/ads' : 'Нужно при аналитике/крашах/рекламе',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppStateScope(
                          notifier: appState,
                          child: _DocScreen(kind: _DocKind.consent, isEn: isEn),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline),
                    title: const Text('Блокировка приложения'),
                    subtitle: const Text('PIN/биометрия при возврате в приложение'),
                    value: lock.enabled,
                    onChanged: (v) async {
                      await appState.updateLockSettings(lock.copyWith(enabled: v));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Автоблокировка'),
                    subtitle: Text(
                      lock.autoLockSeconds == 0
                          ? 'Сразу при уходе из приложения'
                          : 'Через ${lock.autoLockSeconds} сек.',
                    ),
                    onTap: () async {
                      final selected = await showModalBottomSheet<int>(
                        context: context,
                        builder: (context) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              const ListTile(title: Text('Автоблокировка')),
                              for (final s in const [0, 10, 30, 60, 300])
                                RadioListTile<int>(
                                  value: s,
                                  groupValue: lock.autoLockSeconds,
                                  title: Text(
                                    s == 0 ? 'Сразу' : '$s секунд',
                                  ),
                                  onChanged: (v) =>
                                      Navigator.of(context).pop(v),
                                ),
                            ],
                          ),
                        ),
                      );
                      if (selected == null) return;
                      await appState.updateLockSettings(
                        lock.copyWith(autoLockSeconds: selected),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  pinStatus,
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.screenshot_monitor_outlined),
                    title: const Text('Запрет скриншотов (Android)'),
                    subtitle: const Text('Скрывает экран в скриншотах и записи'),
                    value: lock.preventScreenshots,
                    onChanged: (v) async {
                      await appState.updateLockSettings(
                        lock.copyWith(preventScreenshots: v),
                      );
                      await AndroidSecureScreen.setSecure(v);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(isEn ? 'Export data' : 'Экспорт данных'),
                    subtitle: Text(isEn ? 'Copy TXT to clipboard' : 'Скопировать TXT в буфер обмена'),
                    onTap: () async {
                      final txt = _exportTxt(appState, isEn: isEn);
                      await Clipboard.setData(ClipboardData(text: txt));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEn ? 'TXT copied to clipboard' : 'TXT скопирован в буфер обмена',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error),
                    title: const Text('Сбросить все данные'),
                    subtitle: const Text('Удалит задачи, календарь и финансы'),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Сбросить все данные?'),
                          content: const Text(
                            'Это действие нельзя отменить. Данные будут удалены с устройства.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await appState.wipeAllUserData();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Данные удалены')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Примечание: по умолчанию данные хранятся локально на устройстве. '
              'Если в будущем появится облачная синхронизация, это будет вынесено в отдельные настройки и согласия.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _PinFlowKind { create, change }

class _PinFlowScreen extends StatefulWidget {
  const _PinFlowScreen({required this.kind});
  final _PinFlowKind kind;

  @override
  State<_PinFlowScreen> createState() => _PinFlowScreenState();
}

class _PinFlowScreenState extends State<_PinFlowScreen> {
  final _old = TextEditingController();
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = AppStateScope.of(context);
    final oldPin = _old.text.trim();
    final a = _pin1.text.trim();
    final b = _pin2.text.trim();

    if (widget.kind == _PinFlowKind.change) {
      if (oldPin.length < 4) {
        setState(() => _error = 'Введите старый PIN');
        return;
      }
    }
    if (a.length < 4 || b.length < 4) {
      setState(() => _error = 'PIN должен быть минимум 4 цифры');
      return;
    }
    if (a != b) {
      setState(() => _error = 'PIN не совпадает');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    if (widget.kind == _PinFlowKind.change) {
      final ok = await appState.verifyAppPin(oldPin);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _error = 'Старый PIN неверный';
        });
        return;
      }
    }

    await appState.setAppPin(a);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.kind == _PinFlowKind.create ? 'Создать PIN-код' : 'Новый PIN-код';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.kind == _PinFlowKind.change) ...[
              TextField(
                controller: _old,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Старый PIN',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _pin1,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Новый PIN',
                border: const OutlineInputBorder(),
                errorText: widget.kind == _PinFlowKind.create ? _error : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin2,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Повторите новый PIN',
                border: const OutlineInputBorder(),
                errorText: widget.kind == _PinFlowKind.create ? null : _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(widget.kind == _PinFlowKind.create
                  ? 'Установить PIN'
                  : 'Установить новый PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocScreen extends StatelessWidget {
  const _DocScreen({required this.kind, required this.isEn});

  final _DocKind kind;
  final bool isEn;

  String get _assetPath {
    switch (kind) {
      case _DocKind.privacy:
        return isEn ? 'docs/privacy_policy_en.md' : 'docs/privacy_policy.md';
      case _DocKind.terms:
        return isEn ? 'docs/terms_en.md' : 'docs/terms.md';
      case _DocKind.consent:
        return isEn ? 'docs/consent_en.md' : 'docs/consent.md';
    }
  }

  String get _title {
    switch (kind) {
      case _DocKind.privacy:
        return isEn ? 'Privacy Policy' : 'Политика конфиденциальности';
      case _DocKind.terms:
        return isEn ? 'Terms of Use' : 'Условия использования';
      case _DocKind.consent:
        return isEn ? 'Consent (template)' : 'Согласие (шаблон)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: FutureBuilder<String>(
          future: rootBundle.loadString(_assetPath),
          builder: (context, snap) {
            final text = snap.data;
            if (text == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Markdown(
              data: text,
              padding: const EdgeInsets.all(16),
            );
          },
        ),
      ),
    );
  }
}

String _exportTxt(AppState appState, {required bool isEn}) {
  final now = DateTime.now();
  final header = isEn ? 'todoLife export' : 'Экспорт todoLife';
  final when = isEn ? 'Exported at' : 'Дата экспорта';

  final daily = appState.tasks(TaskKind.daily);
  final long = appState.tasks(TaskKind.long);
  final events = appState.calendarEvents;
  final budget = appState.salarySplitDraft;

  final b = StringBuffer();
  b.writeln(header);
  b.writeln('$when: $now');
  b.writeln();

  b.writeln(isEn ? 'Daily tasks:' : 'Задачи на день:');
  if (daily.isEmpty) {
    b.writeln(isEn ? '- (none)' : '- (нет)');
  } else {
    for (final t in daily.reversed) {
      final mark = t.done ? (isEn ? '[x]' : '[x]') : '[ ]';
      b.writeln('- $mark ${t.text}');
    }
  }
  b.writeln();

  b.writeln(isEn ? 'Long-term tasks:' : 'Долгосрочные задачи:');
  if (long.isEmpty) {
    b.writeln(isEn ? '- (none)' : '- (нет)');
  } else {
    for (final t in long.reversed) {
      final mark = t.done ? '[x]' : '[ ]';
      final dl = (t.deadlineDateKey != null && t.deadlineDateKey!.trim().isNotEmpty)
          ? (isEn ? ' (deadline: ${t.deadlineDateKey})' : ' (дедлайн: ${t.deadlineDateKey})')
          : '';
      b.writeln('- $mark ${t.text}$dl');
    }
  }
  b.writeln();

  b.writeln(isEn ? 'Calendar events:' : 'События календаря:');
  if (events.isEmpty) {
    b.writeln(isEn ? '- (none)' : '- (нет)');
  } else {
    for (final e in events.reversed) {
      final time = (e.startTime != null && e.startTime!.trim().isNotEmpty)
          ? (isEn ? ' ${e.startTime}' : ' ${e.startTime}')
          : '';
      b.writeln('- ${e.dateKey}$time — ${e.title}');
      if (e.note != null && e.note!.trim().isNotEmpty) {
        b.writeln('  ${isEn ? "Note" : "Заметка"}: ${e.note}');
      }
    }
  }
  b.writeln();

  b.writeln(isEn ? 'Budget (Funds):' : 'Финансы (Средства):');
  b.writeln('${isEn ? "Salary" : "ЗП"}: ${budget.salary.toStringAsFixed(0)}');
  if (budget.manualAmounts.isNotEmpty) {
    b.writeln(isEn ? 'Amounts:' : 'Суммы:');
    for (final e in budget.manualAmounts.entries) {
      b.writeln('- ${e.key}: ${e.value.toStringAsFixed(0)}');
    }
  }
  if (budget.customAmounts.isNotEmpty) {
    b.writeln(isEn ? 'Custom categories:' : 'Пользовательские категории:');
    for (final e in budget.customAmounts.entries) {
      b.writeln('- ${e.key}: ${e.value.toStringAsFixed(0)}');
    }
  }

  return b.toString();
}

