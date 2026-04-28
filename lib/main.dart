import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

import 'dart:io';

import 'app_state.dart';
import 'router/app_router.dart';
import 'services/notifications_service.dart';
import 'services/user_storage.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/settings/app_lock_screen.dart';
import 'services/android_secure_screen.dart';
import 'ui/scope/app_state_scope.dart';
import 'ui/screens/settings/privacy_onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Some platforms resolve Russian locale as `ru`, others as `ru_RU`.
  await initializeDateFormatting('ru');
  await initializeDateFormatting('ru_RU');
  Intl.defaultLocale = 'ru_RU';
  if (!kIsWeb && Platform.isWindows) {
    SharedPreferencesWindows.registerWith();
  }
  final storage = await UserStorage.open();
  NotificationsService? notifications;
  // Notifications are implemented only for Android (per spec).
  if (!kIsWeb && Platform.isAndroid) {
    notifications = await NotificationsService.createAndInit();
  }
  final appState = AppState(storage, notifications: notifications);
  await appState.init();

  // Android privacy hardening: prevent screenshots if enabled.
  await AndroidSecureScreen.setSecure(appState.lockSettings.preventScreenshots);

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
  AppLifecycleState? _lifecycle;
  late final _LifecycleObserver _observer =
      _LifecycleObserver(widget.appState, onState: (s) {
        if (!mounted) return;
        setState(() => _lifecycle = s);
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

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
            Locale('en', 'US'),
          ],
          locale: widget.appState.locale,
          routerConfig: _appRouter.router,
          builder: (context, child) {
            final locked = widget.appState.lockSettings.enabled && widget.appState.locked;
            // When app is backgrounded/inactive, cover UI to hide it in app switcher.
            final shouldObscure = _lifecycle == AppLifecycleState.inactive ||
                _lifecycle == AppLifecycleState.paused;
            final showOnboarding = widget.appState.showPrivacyOnboarding;
            return Stack(
              children: [
                if (child != null) child,
                if (shouldObscure)
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.black),
                  ),
                if (showOnboarding)
                  Positioned.fill(
                    child: AppStateScope(
                      notifier: widget.appState,
                      child: const Material(
                        color: Colors.black,
                        child: PrivacyOnboardingScreen(),
                      ),
                    ),
                  ),
                if (locked)
                  Positioned.fill(
                    child: AppStateScope(
                      notifier: widget.appState,
                      child: const Material(
                        color: Colors.black,
                        child: AppLockScreen(),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this.appState, {required this.onState});
  final AppState appState;
  final void Function(AppLifecycleState) onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        appState.onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        appState.onAppResumed();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }
}
