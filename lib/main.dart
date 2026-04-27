import 'package:flutter/material.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

import 'dart:io';

import 'app_state.dart';
import 'router/app_router.dart';
import 'services/user_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: widget.appState.themeMode,
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
