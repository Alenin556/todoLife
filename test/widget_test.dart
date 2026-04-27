// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:todolife/app_state.dart';
import 'package:todolife/main.dart';
import 'package:todolife/models/calendar_event.dart';
import 'package:todolife/services/user_storage.dart';
import 'package:todolife/ui/screens/settings/settings_screen.dart';

void main() {
  Future<AppState> pumpApp(WidgetTester tester) async {
    await initializeDateFormatting('ru_RU');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = await UserStorage.open();
    final appState = AppState(storage);
    await appState.init();
    await tester.pumpWidget(MyApp(appState: appState));
    await tester.pumpAndSettle();
    return appState;
  }

  testWidgets('App renders bottom navigation items', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Задачи'), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Финансы'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('Navigation to all main sections works', (WidgetTester tester) async {
    await pumpApp(tester);

    // Daily tasks.
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Сегодня:'), findsOneWidget);

    // Salary split.
    await tester.tap(find.text('Финансы'));
    await tester.pumpAndSettle();
    expect(find.text('Распределение ЗП'), findsOneWidget);

    // Calendar.
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('Вс'), findsOneWidget);

    // Settings.
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Task edit screen opens from daily task list', (WidgetTester tester) async {
    await pumpApp(tester);

    // Daily -> +
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Задача на день'));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);

    // Save to return (edit route is opened via go(), no back stack).
    await tester.enterText(find.byType(TextField).first, 'Тест');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
  });

  testWidgets('Finance: percent chip fills amount; reset clears allocations; save/delete budget works',
      (WidgetTester tester) async {
    final appState = await pumpApp(tester);

    await tester.tap(find.text('Финансы'));
    await tester.pumpAndSettle();
    expect(find.text('Распределение ЗП'), findsOneWidget);

    // Enter salary (editor becomes available immediately).
    final salaryField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Зарплата (ЗП)',
    );
    await tester.enterText(salaryField, '100000');
    await tester.pumpAndSettle();

    expect(find.text('Суммы по категориям'), findsOneWidget);

    // Tap percent helper on first category to auto-fill.
    await tester.tap(find.text('10%').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Подстановка: 10%'), findsWidgets);

    // Scroll down to the save button.
    await tester.scrollUntilVisible(
      find.text('Сохранить'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сохраненные бюджеты'), findsOneWidget);

    // Delete saved budget.
    await tester.scrollUntilVisible(
      find.byTooltip('Удалить'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Удалить').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    // Reset allocations.
    await tester.scrollUntilVisible(
      find.text('Сбросить значения'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Сбросить значения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Подстановка: —'), findsWidgets);
  });

  testWidgets('Task edit: back button prompts on unsaved changes', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Задача на день'));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Несохранено');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Изменения не сохранены'), findsOneWidget);
    await tester.tap(find.text('Остаться'));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);
  });

  testWidgets('Tasks: long-term creation enables segmented toggle', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();

    // Create long task via FAB menu.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Долгосрочная задача'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Цель');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    // Segmented appears once long tasks exist.
    expect(find.text('Долгосрочные'), findsOneWidget);
    await tester.tap(find.text('Долгосрочные'));
    await tester.pumpAndSettle();
    expect(find.text('Цель'), findsOneWidget);
  });

  testWidgets('Calendar: event time is displayed in day view', (WidgetTester tester) async {
    final appState = await pumpApp(tester);

    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await appState.upsertCalendarEvent(
      CalendarEvent(
        id: 'test-event',
        title: 'Встреча',
        dateKey: todayKey,
        startTime: '09:00',
        endTime: '09:30',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();

    // Open today's day view by tapping the day number.
    final dayCell = find.text('${now.day}').first;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(dayCell, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Встреча'), findsOneWidget);
    expect(find.textContaining('09:00–09:30'), findsOneWidget);
  });
}
