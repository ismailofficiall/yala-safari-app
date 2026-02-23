import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/screens/login_screen.dart';
import '../../onboarding/onboarding_screen.dart';

/// Splash screen shown briefly on app launch.
/// Preliminary layout focusing on high-impact park branding.
/// After 2 seconds it checks if onboarding was completed previously (via SharedPreferences),
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  /// Conditionally routes to onboarding or login based on persistence flag
  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool seen = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => seen ? const LoginScreen() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset('assets/images/splash_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
