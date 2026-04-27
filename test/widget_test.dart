// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tofolife/app_state.dart';
import 'package:tofolife/main.dart';
import 'package:tofolife/services/user_storage.dart';

void main() {
  testWidgets('App shows theme toggle', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = await UserStorage.open();
    final appState = AppState(storage);
    await appState.init();

    await tester.pumpWidget(MyApp(appState: appState));

    expect(find.text('todoLife'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });
}
