import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

import 'dart:io';

import 'app_state.dart';
import 'router/app_router.dart';
import 'services/user_storage.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Some platforms resolve Russian locale as `ru`, others as `ru_RU`.
  await initializeDateFormatting('ru');
  await initializeDateFormatting('ru_RU');
  Intl.defaultLocale = 'ru_RU';
  if (Platform.isWindows) {
    SharedPreferencesWindows.registerWith();
  }
  final storage = await UserStorage.open();
  final appState = AppState(storage);
  await appState.init();
  runApp(MyApp(appState: appState));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(widget.appState);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        if (!widget.appState.ready) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'todoLife',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.appState.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
          ],
          locale: const Locale('ru', 'RU'),
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
