import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:soka/firebase_options.dart';

import 'package:soka/screens/home_screen.dart';
import 'package:soka/screens/login_screen.dart';
import 'package:soka/screens/signup_screen.dart';
import 'package:soka/screens/event_details_screen.dart';
import 'package:soka/screens/notifications_screen.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(AppState());
}

class AppState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SokaService())],
      child: MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ligthTheme,
      title: 'SOKA',
      initialRoute: 'homePage',
      routes: {
        'homePage': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const SignupScreen(),
        'notifications': (context) => const NotificationsScreen(),
        //'registerCompany': (context) => const RegisterCompanyScreen(),
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
