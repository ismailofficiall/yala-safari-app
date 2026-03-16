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
    // Mimic real-world network latency for better UX/UI feedback
    await Future.delayed(const Duration(milliseconds: 300));

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

      // Verify driver account status

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
          Container(color: Colors.black.withValues(alpha: 0.6)),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
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
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: DropdownButton<String>(
                                dropdownColor: Colors.black,
                                value: langProvider.lang,
                                icon: const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
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
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tab selector with better glassmorphism
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white60,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            tabs: const [
                              Tab(text: '🚗  Driver'),
                              Tab(text: '🛡️  Admin'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tab content wrapped in padding to prevent overflow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _tabController.index == 0 ? 320 : 280,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // ── DRIVER TAB ──
                              Column(
                                children: [
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: AppTranslations.t('username'),
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: AppTranslations.t('password'),
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    obscure: _obscureDriver,
                                    onToggle: () => setState(() => _obscureDriver = !_obscureDriver),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSubmitButton(
                                    onPressed: _loginDriver,
                                    label: AppTranslations.t('login'),
                                    color: Colors.green.shade800,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSignUpScreen())),
                                    child: const Text("Don't have an account? Create one", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              // ── ADMIN TAB ──
                              Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Admin Email',
                                    icon: Icons.admin_panel_settings_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _adminPasswordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    obscure: _obscureAdmin,
                                    onToggle: () => setState(() => _obscureAdmin = !_obscureAdmin),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSubmitButton(
                                    onPressed: _loginAdmin,
                                    label: 'Sign in as Admin',
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? obscure,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure ?? false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white70, width: 1.5),
        ),
        suffixIcon: isPassword ? IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white60,
            size: 18,
          ),
        ) : null,
      ),
    );
  }

  Widget _buildSubmitButton({required VoidCallback onPressed, required String label, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.4),
        ),
        child: _loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }
}
