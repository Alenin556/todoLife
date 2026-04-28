import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../scope/app_state_scope.dart';

class PrivacyOnboardingScreen extends StatelessWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isEn = appState.locale.languageCode == 'en';

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEn ? 'Protect your data' : 'Защитите ваши данные',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'You can set a PIN to protect tasks and finance screens if someone gets access to your phone.'
                            : 'Можно установить PIN-код, чтобы защитить задачи и финансы, если кто-то возьмёт телефон.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => const _SetPinDialog(),
                          );
                          if (!context.mounted) return;
                          if (ok == true) {
                            await appState.updateLockSettings(
                              appState.lockSettings.copyWith(enabled: true),
                            );
                          }
                          await appState.dismissPrivacyOnboarding();
                        },
                        child: Text(isEn ? 'Set PIN' : 'Установить PIN'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await appState.dismissPrivacyOnboarding();
                        },
                        child: Text(isEn ? 'Skip for now' : 'Позже'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'You can always change this later in Settings → Privacy.'
                            : 'Можно изменить позже в Настройки → Конфиденциальность.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
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
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN-код'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Установить'),
        ),
      ],
    );
  }
}

