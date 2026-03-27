import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';

/// Screen responsible for handling new driver self-registration.
/// This connects directly to the Supabase 'drivers' table to create
/// a new authenticated driver record.
class DriverSignUpScreen extends StatefulWidget {
  const DriverSignUpScreen({super.key});

  @override
  State<DriverSignUpScreen> createState() => _DriverSignUpScreenState();
}

class _DriverSignUpScreenState extends State<DriverSignUpScreen> {
  // GlobalKey used to validate the entire registration form
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Controllers to capture user input data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _jeepController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // State variables for UI feedback
  bool _isLoading = false;
  bool _obscurePassword = true;
  XFile? _profileImage;
  bool _isVerified = false;
  bool _otpSent = false;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _idController.dispose();
    _jeepController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid phone number")));
      return;
    }
    
    // Attempt to send a real SMS via Supabase Auth providers
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true, // This effectively registers them in auth.users too
      );
      
      setState(() {
        _otpSent = true;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification code sent to your phone via SMS"),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sending SMS. Ensure you've enabled a phone provider in Supabase: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    
    try {
      final res = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      
      if (res.session != null || res.user != null) {
        setState(() => _isVerified = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number verified!"), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid or expired OTP code: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Submits the registration form to the Supabase backend.
  /// Validates input, constructs the payload, and performs an async network request.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a profile photo")));
      return;
    }

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please verify your phone number using the OTP")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload Profile Photo
      final fileName = "profile_${const Uuid().v4()}";
      String ext = path.extension(_profileImage!.name);
      if (ext.isEmpty) ext = '.jpg';
      final filePath = "profile-pictures/$fileName$ext";
      
      final bytes = await _profileImage!.readAsBytes();
      await _supabase.storage.from('incident-images').uploadBinary(
        filePath, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _supabase.storage.from('incident-images').getPublicUrl(filePath);

      // 2. Create Driver Record
      await _supabase.from('drivers').insert({
        'driver_name': _nameController.text.trim(),
        'driver_id_code': _idController.text.trim(),
        'jeep_id': _jeepController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'image_url': imageUrl,
        'status': 'Active',
        'rating': 5.0,
      });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful! You can now log in.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context); // Return to login screen
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration Failed: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Driver Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withValues(alpha: 0.75)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Join the Fleet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Fill out your details below to register your vehicle.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Profile Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            backgroundImage: _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                            child: _profileImage == null
                                ? const Icon(Icons.add_a_photo, color: Colors.white70, size: 30)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Upload Profile Photo", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 30),

                      _buildTextField(_nameController, "Full Name", Icons.person, "Enter your full name"),
                      const SizedBox(height: 16),
                      _buildTextField(_idController, "NIC / Driver ID", Icons.badge, "Enter your ID (e.g. NIC or License)"),
                      const SizedBox(height: 16),
                      _buildTextField(_jeepController, "Jeep License Plate", Icons.directions_car, "Enter vehicle plate"),
                      const SizedBox(height: 30),

                      const Text(
                        "Security Verification",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_phoneController, "Phone Number", Icons.phone, "Enter phone number")),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isVerified ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            child: Text(_otpSent ? "Resend" : "Send OTP"),
                          ),
                        ],
                      ),
                      if (_otpSent && !_isVerified) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_otpController, "Enter OTP", Icons.lock_clock, "Enter code")),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _verifyOtp,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text("Verify"),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 30),

                      const Text(
                        "Login Credentials",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_usernameController, "Choose a Username", Icons.account_circle, "Set a username"),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      
                      const SizedBox(height: 40),
                      
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm, // Prevent multiple clicks during network request
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Create Account', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to construct standardized form text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String errorMsg) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? errorMsg : null,
    );
  }

  /// Helper method to construct the password field with a toggleable obscure icon
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Choose a Password",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword), // Toggle password visibility state
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? "Set a password" : null,
    );
  }
}
