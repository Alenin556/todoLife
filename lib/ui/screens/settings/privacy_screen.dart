import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../scope/app_state_scope.dart';
import '../../../services/android_secure_screen.dart';

enum _DocKind { privacy, terms, consent }

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final lock = appState.lockSettings;
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
                    title: const Text('Политика конфиденциальности'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _DocScreen(kind: _DocKind.privacy),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Условия использования'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _DocScreen(kind: _DocKind.terms),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Согласие (шаблон)'),
                    subtitle: const Text('Нужно при аналитике/крашах/рекламе'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _DocScreen(kind: _DocKind.consent),
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
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('PIN-код'),
                    subtitle: const Text('Установить/изменить PIN'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _PinSetupScreen(),
                        ),
                      );
                    },
                  ),
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
                    title: const Text('Экспорт данных'),
                    subtitle: const Text('Скопировать JSON в буфер обмена'),
                    onTap: () async {
                      final json = appState.exportUserDataJson();
                      await Clipboard.setData(ClipboardData(text: json));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('JSON скопирован в буфер обмена')),
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

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen();

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final appState = AppStateScope.of(context);
    final a = _pin1.text.trim();
    final b = _pin2.text.trim();
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
    await appState.setAppPin(a);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('PIN-код')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _pin1,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Новый PIN',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin2,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Повторите PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Сохранить PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocScreen extends StatelessWidget {
  const _DocScreen({required this.kind});

  final _DocKind kind;

  String get _assetPath {
    switch (kind) {
      case _DocKind.privacy:
        return 'docs/privacy_policy.md';
      case _DocKind.terms:
        return 'docs/terms.md';
      case _DocKind.consent:
        return 'docs/consent.md';
    }
  }

  String get _title {
    switch (kind) {
      case _DocKind.privacy:
        return 'Политика конфиденциальности';
      case _DocKind.terms:
        return 'Условия использования';
      case _DocKind.consent:
        return 'Согласие (шаблон)';
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

