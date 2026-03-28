// =========================================================================
// Entry Point of the Yala Safari Driver Application
// =========================================================================
// This file serves as the main entry point for the Flutter application. 
// It handles core initialization tasks such as binding the framework, 
// initializing Firebase and Supabase services, setting up global state 
// management (Providers), and defining the root routing structure.
//
// Coursework Note: 
// Utilizing `runApp` with a `ChangeNotifierProvider` ensures that global
// state (like language translation preferences) can be accessed from any 
// screen deep within the widget tree without needing to pass variables 
// manually through constructors.
// =========================================================================

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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase configurations for background services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Supabase client for database handling and authentication.
  await SupabaseConfig.init();

  runApp(
    // Wrap the entire app in a ChangeNotifierProvider to manage global 
    // state. In this case, `LanguageProvider` will listen for locale
    // changes and cause the sub-tree to rebuild automatically.
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

      // Routes Map: A dictionary of key-value pairs defining the named
      // routes for navigation throughout the app without needing to pass
      // context deeply across files.
      routes: {
        '/splash': (c) => const SplashScreen(),
        '/': (c) => const LoginScreen(),
        '/incident': (c) => const IncidentReportScreen(),
      },
    );
  }
}
