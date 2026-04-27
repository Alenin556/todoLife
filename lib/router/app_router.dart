import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../ui/scope/app_state_scope.dart';
import '../ui/shell/app_scaffold.dart';
import '../ui/screens/finance/deposit_calculator_screen.dart';
import '../ui/screens/finance/salary_split_screen.dart';
import '../ui/screens/calendar/calendar_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/quotes_home_screen.dart';
import '../ui/screens/tasks/task_edit_screen.dart';
import '../ui/screens/tasks/task_list_screen.dart';

class AppRouter {
  AppRouter(this.appState);

  final AppState appState;

  late final GoRouter router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppStateScope(
            notifier: appState,
            child: AppScaffold(
              appState: appState,
              location: state.matchedLocation,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/motivation',
            builder: (context, state) => const QuotesHomeScreen(),
          ),
          GoRoute(
            path: '/tasks/daily',
            builder: (context, state) =>
                const TaskListScreen(kind: TaskKind.daily),
          ),
          GoRoute(
            path: '/tasks/long',
            builder: (context, state) =>
                const TaskListScreen(kind: TaskKind.long),
          ),
          GoRoute(
            path: '/finance/salary',
            builder: (context, state) => const SalarySplitScreen(),
          ),
          GoRoute(
            path: '/finance/deposit',
            builder: (context, state) => const DepositCalculatorScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tasks/:kind/edit',
        builder: (context, state) {
          final kindParam = state.pathParameters['kind'];
          final kind = TaskKindX.tryParse(kindParam) ?? TaskKind.daily;
          final taskId = state.uri.queryParameters['id'];
          return AppStateScope(
            notifier: appState,
            child: TaskEditScreen(kind: kind, taskId: taskId),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('todoLife')),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown error')),
    ),
  );
}

