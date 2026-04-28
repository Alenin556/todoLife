import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../ui/scope/app_state_scope.dart';
import '../ui/shell/app_scaffold.dart';
import '../ui/screens/finance/finance_root_screen.dart';
import '../ui/screens/calendar/calendar_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/quotes_home_screen.dart';
import '../ui/screens/settings/settings_screen.dart';
import '../ui/screens/settings/privacy_screen.dart';
import '../ui/screens/tasks/task_edit_screen.dart';
import '../ui/screens/tasks/task_list_screen.dart';

class AppRouter {
  AppRouter(this.appState);

  final AppState appState;

  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/finance/salary',
        redirect: (context, state) => '/finance',
      ),
      GoRoute(
        path: '/finance/deposit',
        redirect: (context, state) => '/finance',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppStateScope(
            notifier: appState,
            child: AppScaffold(
              appState: appState,
              navigationShell: navigationShell,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'motivation',
                    builder: (context, state) => const QuotesHomeScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (context, state) => const FinanceRootScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => AppStateScope(
          notifier: appState,
          child: const PrivacyScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks/edit',
        builder: (context, state) {
          final kindParam = state.uri.queryParameters['kind'];
          final kind = TaskKindX.tryParse(kindParam) ?? TaskKind.daily;
          final taskId = state.uri.queryParameters['id'];
          return AppStateScope(
            notifier: appState,
            child: TaskEditScreen(kind: kind, taskId: taskId),
          );
        },
      ),
      // Backward-compatible route (old deep links).
      GoRoute(
        path: '/tasks/:kind/edit',
        redirect: (context, state) {
          final kind = state.pathParameters['kind'];
          final id = state.uri.queryParameters['id'];
          final qp = <String, String>{
            'kind': kind ?? 'daily',
            if (id != null) 'id': id,
          };
          return Uri(path: '/tasks/edit', queryParameters: qp).toString();
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('todoLife')),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown error')),
    ),
  );
}

