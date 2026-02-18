import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:soka/firebase_options.dart';

import 'package:soka/features/home/presentation/screens/home_screen.dart';
import 'package:soka/features/auth/presentation/screens/login_screen.dart';
import 'package:soka/features/auth/presentation/screens/signup_screen.dart';
import 'package:soka/features/events/presentation/screens/event_details_screen.dart';
import 'package:soka/features/home/presentation/screens/notifications_screen.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_theme.dart';

final ValueNotifier<String?> _globalErrorMessage = ValueNotifier<String?>(null);

void _showErrorOnScreen(Object error) {
  _globalErrorMessage.value = error.toString();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  ErrorWidget.builder = (details) {
    _showErrorOnScreen(details.exception);
    return Material(
      color: Colors.red.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  };

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
      _showErrorOnScreen(errorDetails.exception);
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _showErrorOnScreen(error);
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
      _showErrorOnScreen(errorDetails.exception);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _showErrorOnScreen(error);
      return false;
    };
  }

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccessibilityService>(
          create: (_) => AccessibilityService(),
        ),
        ChangeNotifierProvider<SokaService>(create: (_) => SokaService()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(highContrast: accessibility.highContrast),
      darkTheme: AppTheme.darkTheme(highContrast: accessibility.highContrast),
      themeMode: accessibility.themeMode,
      themeAnimationDuration: accessibility.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      title: 'SOKA',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return Stack(
          children: [
            MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(accessibility.textScaleFactor),
                boldText: accessibility.boldText,
                accessibleNavigation: accessibility.reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _globalErrorMessage,
              builder: (context, errorMessage, _) {
                if (errorMessage == null || errorMessage.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: mediaQuery.padding.top + 8,
                  left: 8,
                  right: 8,
                  child: Material(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      initialRoute: '/',
      routes: {
        'homePage': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const SignupScreen(),
        'notifications': (context) => const NotificationsScreen(),
        '/': (context) => const AuthGate(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == 'details') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          );
        }
        return null;
      },
    );
  }
}
