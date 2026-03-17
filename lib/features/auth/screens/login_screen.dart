import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/translations/language_provider.dart';
import '../../../core/translations/app_translations.dart';
import '../../dashboard/driver_dashboard_screen.dart';
import '../../admin/services/admin_service.dart';
import '../../admin/shell/admin_shell.dart';
import 'driver_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Driver login
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Admin login
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureDriver = true;
  bool _obscureAdmin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  // ──────────────── DRIVER LOGIN ────────────────
  Future<void> _loginDriver() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage("Enter username and password");
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        _showMessage("Invalid driver credentials");
        setState(() => _loading = false);
        return;
      }

      final status = response['status']?.toString();
      if (status == 'Suspended') {
        _showMessage("Your account has been suspended by an admin.");
        setState(() => _loading = false);
        return;
      }

      final driverId = response['id'].toString();
      final jeepId = response['jeep_id'] ?? "Unknown";
      final block = response['block'] ?? "Unknown";

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardScreen(driverId: driverId, jeepId: jeepId, block: block),
        ),
      );
    } catch (e) {
      _showMessage("Login failed: $e");
    }

    setState(() => _loading = false);
  }

  // ──────────────── ADMIN LOGIN ────────────────
  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _adminPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Enter email and password");
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);

      final access = await AdminService.checkAdminAccess();

      if (!mounted) return;

      if (access == AdminAccess.allowed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      } else if (access == AdminAccess.denied) {
        await Supabase.instance.client.auth.signOut();
        _showMessage("Access denied. Not an admin account.");
      } else {
        await Supabase.instance.client.auth.signOut();
        _showMessage("Admin setup incomplete. Contact your administrator.");
      }
    } on AuthException catch (e) {
      _showMessage("Login failed: ${e.message}");
    } catch (e) {
      _showMessage("Login failed: $e");
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.6)),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "YALA 360",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: langProvider.lang,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text("English")),
                          DropdownMenuItem(value: 'si', child: Text("සිංහල")),
                          DropdownMenuItem(value: 'ta', child: Text("தமிழ்")),
                        ],
                        onChanged: (value) {
                          if (value != null) langProvider.changeLanguage(value);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // LOGIN title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tab selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: '🚗  Driver'),
                        Tab(text: '🛡️  Admin'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tab content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 290,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── DRIVER TAB ──
                        Column(
                          children: [
                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                labelText: AppTranslations.t('username'),
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscureDriver,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                labelText: AppTranslations.t('password'),
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscureDriver = !_obscureDriver),
                                  icon: Icon(
                                    _obscureDriver ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _loginDriver,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(AppTranslations.t('login'), style: const TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DriverSignUpScreen()),
                                );
                              },
                              child: const Text(
                                "Don't have an account? Sign Up",
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // ── ADMIN TAB ──
                        Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                labelText: 'Admin Email',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _adminPasswordController,
                              obscureText: _obscureAdmin,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscureAdmin = !_obscureAdmin),
                                  icon: Icon(
                                    _obscureAdmin ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _loginAdmin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Sign in as Admin', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
