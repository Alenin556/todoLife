import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../scope/app_state_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isEn = appState.locale.languageCode == 'en';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isEn ? 'Settings' : 'Настройки',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.color_lens_outlined, color: scheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEn ? 'Theme' : 'Тема',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: <ThemeMode>{appState.themeMode},
                    onSelectionChanged: (v) => appState.setTheme(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.language_outlined, color: scheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEn ? 'Language' : 'Язык',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ru', label: Text('RU')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {isEn ? 'en' : 'ru'},
                    onSelectionChanged: (v) => appState.setLanguageCode(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(isEn ? 'Privacy' : 'Конфиденциальность'),
                  subtitle: Text(
                    isEn
                        ? 'Policy, terms, data controls'
                        : 'Политика, условия, управление данными',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/privacy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

