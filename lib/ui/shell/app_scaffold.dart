import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.appState,
    required this.navigationShell,
  });

  final AppState appState;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('todoLife')),
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? scheme.surfaceContainerHighest : scheme.surface)
                  .withValues(alpha: isDark ? 0.65 : 0.92),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.9),
              ),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: onTap,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: scheme.onSurface,
              unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist_outlined),
                  label: 'Задачи',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Календарь',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Финансы',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Настройки',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

