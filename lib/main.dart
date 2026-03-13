// Entry point for the Yala Safari Driver App.


import 'package:flutter/material.dart';
import 'core/services/supabase_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/driver_dashboard_screen.dart';
import 'features/incidents/screens/incident_report_screen.dart';
import 'features/splash/screens/splash_screen.dart'; 
import 'core/constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'core/translations/language_provider.dart';

/// The `main` method is the starting point of the application execution.
/// It is declared as `async` because external services (Firebase, Supabase)
/// usually require network calls to initialize their backend connections.
void main() async {
  // Ensures Flutter's core widget binding engine is initialized before 
  // attempting to communicate with native platform channels.
  // Preloads core UI assets from the localized bundle.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase configurations for background services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Supabase client for database handling and authentication.
  await SupabaseConfig.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const DriverApp(),
    ),
  );
}

/// The root `StatelessWidget` representing the entire application UI tree.
/// It configures the `MaterialApp` settings including the theme, routes, 
/// and title of the app.
class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yala Safari Driver',
      debugShowCheckedModeBanner: false, // Hides the "DEBUG" banner.
      
      // Inject our custom predefined Premium Safari theme globally
      theme: AppTheme.lightTheme,

      // Initial Route determines which screen launches first.
      initialRoute: '/splash',

      // Named routes
      routes: {
        '/splash': (c) => const SplashScreen(),
        '/': (c) => const LoginScreen(),
        '/incident': (c) => const IncidentReportScreen(),
      },
    );
  }
}
