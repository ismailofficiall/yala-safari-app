import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/screens/login_screen.dart';
import '../../core/constants/app_theme.dart';

/// Displays a 3-step onboarding flow for first-time users.
/// Uses SharedPreferences to store whether the user has already seen it,
/// so it is shown exactly once per device installation.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Page controller to animate transitions between onboarding slides
  final PageController _controller = PageController();
  int _currentPage = 0;

  /// Represents each onboarding slide's content
  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.forest_rounded,
      color: AppTheme.primaryGreen,
      title: "Welcome to Yala Driver",
      subtitle: "Your intelligent companion for safe and efficient safari operations inside Yala National Park.",
    ),
    _OnboardingData(
      icon: Icons.warning_amber_rounded,
      color: Colors.deepOrange,
      title: "Report Incidents Instantly",
      subtitle: "Capture wildlife sightings, emergencies, or breakdowns with photos and GPS coordinates — even offline.",
    ),
    _OnboardingData(
      icon: Icons.gps_fixed_rounded,
      color: Colors.blue,
      title: "Stay Connected to HQ",
      subtitle: "Your live location is shared with the operations center. An SOS panic button is always within reach.",
    ),
  ];

  /// Mark onboarding as complete in SharedPreferences and navigate to login
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button in top-right corner
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text("Skip", style: TextStyle(color: AppTheme.greyText)),
                ),
              ),
            ),

            // PageView containing each slide
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Colored icon in a large circle container
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: page.color.withValues(alpha: 0.12),
                            ),
                            child: Icon(page.icon, size: 72, color: page.color),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.greyText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Progress indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i ? AppTheme.primaryGreen : AppTheme.greyText.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Navigation button - "Next" or "Get Started"
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? "Next" : "Get Started",
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model holding the content for a single onboarding slide
class _OnboardingData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
