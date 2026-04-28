import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todolife/app_state.dart';
import 'package:todolife/services/analytics_service.dart';
import 'package:todolife/services/user_storage.dart';

class _FakeAnalyticsService extends AnalyticsService {
  final List<({String name, Map<String, Object?> params})> events = [];

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    events.add((name: name, params: params));
  }
}

void main() {
  test('Daily analytics: sends daily_summary once on day rollover', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      // consent_analytics_enabled_v1
      'consent_analytics_enabled_v1': true,
      // analytics counters stored for previous day
      'analytics_counters_date_v1': '2026-04-27',
      'analytics_counters_json_v1': jsonEncode(<String, int>{'nav_tab': 5}),
    });

    final storage = await UserStorage.open();
    final fake = _FakeAnalyticsService();
    final appState = AppState(storage, analytics: fake);
    await appState.init();

    final summary = fake.events.where((e) => e.name == 'daily_summary').toList();
    expect(summary.length, 1);
    expect(summary.first.params['day'], '2026-04-27');
    expect(summary.first.params['counts'], isA<Map>());
  });

  test('Analytics counters: logAnalyticsEvent increments and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'consent_analytics_enabled_v1': true,
    });
    final storage = await UserStorage.open();
    final fake = _FakeAnalyticsService();
    final appState = AppState(storage, analytics: fake);
    await appState.init();

    await appState.logAnalyticsEvent('nav_tab', params: const {'index': 1});

    final raw = storage.loadAnalyticsCountersJson();
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!);
    expect(decoded, isA<Map>());
    expect((decoded as Map)['nav_tab'], 1);
  });

  test('Bug report: includes user message and recent logs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'consent_analytics_enabled_v1': false,
    });
    final storage = await UserStorage.open();
    final appState = AppState(storage);
    await appState.init();

    appState.recordError(Exception('boom'), StackTrace.current, context: 'test');
    final report = appState.buildBugReport(userMessage: 'Steps to reproduce');

    expect(report, contains('Steps to reproduce'));
    expect(report, contains('boom'));
    expect(report, contains('recent_logs:'));
  });
}

