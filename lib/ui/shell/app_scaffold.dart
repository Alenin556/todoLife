import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.appState,
    required this.location,
    required this.child,
  });

  final AppState appState;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('todoLife')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Text(
                  'Меню',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              _NavTile(
                tileKey: const ValueKey('nav_daily'),
                selected: _isSelected('/tasks/daily'),
                icon: Icons.today_outlined,
                title: 'Задачи на день',
                onTap: () => _go(context, '/tasks/daily'),
              ),
              _NavTile(
                tileKey: const ValueKey('nav_long'),
                selected: _isSelected('/tasks/long'),
                icon: Icons.event_note_outlined,
                title: 'Долгосрочные задачи',
                onTap: () => _go(context, '/tasks/long'),
              ),
              _NavTile(
                tileKey: const ValueKey('nav_salary'),
                selected: _isSelected('/finance/salary'),
                icon: Icons.account_balance_wallet_outlined,
                title: 'Подсчет финансов (ЗП)',
                onTap: () => _go(context, '/finance/salary'),
              ),
              _NavTile(
                tileKey: const ValueKey('nav_deposit'),
                selected: _isSelected('/finance/deposit'),
                icon: Icons.savings_outlined,
                title: 'Подсчет вкладов',
                onTap: () => _go(context, '/finance/deposit'),
              ),
              _NavTile(
                tileKey: const ValueKey('nav_calendar'),
                selected: _isSelected('/calendar'),
                icon: Icons.calendar_month_outlined,
                title: 'Календарь',
                onTap: () => _go(context, '/calendar'),
              ),
              const Divider(),
              _NavTile(
                tileKey: const ValueKey('nav_quotes'),
                selected: _isSelected('/'),
                icon: Icons.auto_awesome_outlined,
                title: 'Мотивация',
                onTap: () => _go(context, '/'),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemeMode>(
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
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  bool _isSelected(String route) => location == route || location.startsWith('$route/');

  void _go(BuildContext context, String route) {
    Navigator.of(context).maybePop();
    if (location != route) {
      context.go(route);
    }
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.tileKey,
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Key tileKey;
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: onTap,
    );
  }
}

