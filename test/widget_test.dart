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
    expect(find.text('Новая задача'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Несохранено');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Изменения не сохранены'), findsOneWidget);
    await tester.tap(find.text('Остаться'));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);
  });
}
