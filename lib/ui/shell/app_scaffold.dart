import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (kIsWeb) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _WebTopNav(
                  currentIndex: navigationShell.currentIndex,
                  onSelectIndex: (i) {
                    // ignore: discarded_futures
                    appState.logAnalyticsEvent('nav_tab', params: {'index': i});
                    navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    );
                  },
                  appState: appState,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('todoLife')),
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          // ignore: discarded_futures
          appState.logAnalyticsEvent('nav_tab', params: {'index': i});
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _WebTopNav extends StatelessWidget {
  const _WebTopNav({
    required this.currentIndex,
    required this.onSelectIndex,
    required this.appState,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectIndex;
  final AppState appState;

  static const _items = <({int index, String label})>[
    (index: 0, label: 'Home'),
    (index: 1, label: 'Tasks'),
    (index: 2, label: 'Calendar'),
    (index: 3, label: 'Finance'),
    (index: 4, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 900;

        return Row(
          children: [
            // Left logo mark
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelectIndex(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'tl',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.92),
                    fontSize: 14,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const Spacer(),

            if (!compact) ...[
              for (final it in _items) ...[
                _WebNavItem(
                  label: it.label,
                  active: currentIndex == it.index,
                  onTap: () => onSelectIndex(it.index),
                ),
                const SizedBox(width: 12),
              ],
              const SizedBox(width: 4),
            ] else ...[
              IconButton(
                tooltip: 'Menu',
                onPressed: () async {
                  final overlay = Overlay.of(context).context.findRenderObject();
                  final box = context.findRenderObject() as RenderBox?;
                  if (overlay == null || box == null) return;
                  final pos = box.localToGlobal(Offset.zero);
                  final selected = await showMenu<int>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      pos.dx + c.maxWidth - 4,
                      pos.dy + 44,
                      16,
                      0,
                    ),
                    items: [
                      for (final it in _items)
                        PopupMenuItem<int>(
                          value: it.index,
                          child: Text(it.label),
                        ),
                    ],
                  );
                  if (selected != null) onSelectIndex(selected);
                },
                icon: const Icon(Icons.menu),
              ),
              const SizedBox(width: 8),
            ],

            // Right icons (theme toggle + more)
            _IconGlass(
              child: IconButton(
                tooltip: isDark ? 'Light' : 'Dark',
                onPressed: () {
                  appState.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                },
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              ),
            ),
            const SizedBox(width: 8),
            _IconGlass(
              child: IconButton(
                tooltip: 'Open settings',
                onPressed: () => onSelectIndex(4),
                icon: const Icon(Icons.tune),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WebNavItem extends StatelessWidget {
  const _WebNavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface.withValues(alpha: active ? 0.92 : 0.65);
    final border = scheme.onSurface.withValues(alpha: active ? 0.5 : 0.0);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
          color: Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IconGlass extends StatelessWidget {
  const _IconGlass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.65),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.9),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(height: 40, width: 40, child: child),
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

