import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../scope/app_state_scope.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  bool? _hasPin;
  bool? _deviceAuthAvailable;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _init(AppState appState) async {
    if (_hasPin != null && _deviceAuthAvailable != null) return;
    final hasPin = await appState.appLockHasPin();
    final dev = await appState.deviceAuthAvailable();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _deviceAuthAvailable = dev;
    });
  }

  Future<void> _unlockWithPin(AppState appState) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await appState.verifyAppPin(_pin.text.trim());
    if (!mounted) return;
    if (ok) {
      appState.unlock();
    } else {
      setState(() => _error = 'Неверный PIN');
    }
    setState(() => _busy = false);
  }

  Future<void> _unlockWithDevice(AppState appState) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await appState.authenticateWithDevice();
    if (!mounted) return;
    if (ok) {
      appState.unlock();
    } else {
      setState(() => _error = 'Не удалось подтвердить');
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    _init(appState);

    final hasPin = _hasPin ?? false;
    final dev = _deviceAuthAvailable ?? false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                        'Приложение заблокировано',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Введите PIN или подтвердите биометрию.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (hasPin)
                        TextField(
                          controller: _pin,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            border: const OutlineInputBorder(),
                            errorText: _error,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (hasPin)
                        FilledButton(
                          onPressed: _busy ? null : () => _unlockWithPin(appState),
                          child: const Text('Разблокировать'),
                        ),
                      if (dev) ...[
                        if (hasPin) const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _busy ? null : () => _unlockWithDevice(appState),
                          child: const Text('Использовать биометрию/пароль устройства'),
                        ),
                      ],
                      if (!hasPin && !dev)
                        Text(
                          'На этом устройстве недоступна биометрия/пароль.\n'
                          'В настройках выключите блокировку приложения.',
                          textAlign: TextAlign.center,
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

