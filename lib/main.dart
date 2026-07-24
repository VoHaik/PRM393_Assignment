// HistoryTalk Application Entry Point
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'data/datasources/local/hive_helper.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/auth_bloc.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/main_tabs_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  // Ensure widgets binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Analytics & Crashlytics)
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Dependency Injection
  await di.init();

  // Initialize Offline Hive Cache
  await HiveHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, _) {
          return MaterialApp(
            title: 'HistoryTalk',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthGateScreen(),
          );
        },
      ),
    );
  }
}

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          // Splash screen loader
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 72,
                    color: accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HistoryTalk',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: accentColor),
                ],
              ),
            ),
          );
        }

        if (state is Authenticated) {
          return const MainTabsScreen();
        }

        // Default or unauthenticated
        return const LoginScreen();
      },
    );
  }
}
