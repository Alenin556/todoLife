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
  Future<void> pumpApp(WidgetTester tester) async {
    await initializeDateFormatting('ru_RU');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = await UserStorage.open();
    final appState = AppState(storage);
    await appState.init();
    await tester.pumpWidget(MyApp(appState: appState));
    await tester.pumpAndSettle();
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
}
