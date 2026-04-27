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

import 'package:tofolife/app_state.dart';
import 'package:tofolife/main.dart';
import 'package:tofolife/services/user_storage.dart';

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

  testWidgets('App renders Drawer menu items', (WidgetTester tester) async {
    await pumpApp(tester);

    // Open drawer.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nav_daily')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_long')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_salary')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_deposit')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_calendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_quotes')), findsOneWidget);
  });

  testWidgets('Navigation to all main sections works', (WidgetTester tester) async {
    await pumpApp(tester);

    Future<void> openDrawer() async {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
    }

    // Daily tasks.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_daily')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Сегодня:'), findsOneWidget);

    // Long tasks.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_long')));
    await tester.pumpAndSettle();
    expect(find.text('Долгосрочные задачи'), findsOneWidget);

    // Salary split.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_salary')));
    await tester.pumpAndSettle();
    expect(find.text('Распределение ЗП'), findsOneWidget);

    // Deposit.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_deposit')));
    await tester.pumpAndSettle();
    expect(find.text('Депозитный калькулятор'), findsOneWidget);

    // Calendar.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_calendar')));
    await tester.pumpAndSettle();
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('Вс'), findsOneWidget);

    // Quotes home.
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_quotes')));
    await tester.pumpAndSettle();
    expect(find.text('Новая цитата'), findsOneWidget);
  });

  testWidgets('Task edit screen opens from both task lists', (WidgetTester tester) async {
    await pumpApp(tester);

    Future<void> openDrawer() async {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
    }

    // Daily -> +
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_daily')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);

    // Save to return (edit route is opened via go(), no back stack).
    await tester.enterText(find.byType(TextField).first, 'Тест');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    // Long -> +
    await openDrawer();
    await tester.tap(find.byKey(const ValueKey('nav_long')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Новая задача'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Тест2');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
  });
}
