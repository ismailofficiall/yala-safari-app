import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _jeepController = TextEditingController();
  
  // Credentials for the newly registered driver
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _status = 'Active';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _jeepController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _supabase.from('drivers').insert({
          'driver_name': _nameController.text.trim(),
          'driver_id_code': _idController.text.trim(),
          'jeep_id': _jeepController.text.trim(),
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
          'status': _status,
          'rating': 5.0,
        });

        // Insert record into the audit log
        await _supabase.from('audit_logs').insert({
          'action': 'New Driver Added',
          'entity': _nameController.text.trim(),
          'performed_by': 'Admin',
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver Registered Successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New driver', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              'Register for the park fleet',
              style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.greyText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(context, 'Driver information'),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "Full Name", Icons.person, "Please enter a name"),
              const SizedBox(height: 15),
              _buildTextField(_idController, "Driver ID (e.g. DRV-101)", Icons.badge, "Please enter an ID"),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: "Status",
                  prefixIcon: const Icon(Icons.info, color: AppTheme.greyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                ),
                dropdownColor: Theme.of(context).cardTheme.color,
                items: ['Active', 'Suspended', 'Probation'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _status = newValue!),
              ),
              const SizedBox(height: 30),
              
              _buildSectionTitle(context, 'Login Credentials'),
              const SizedBox(height: 15),
              _buildTextField(_usernameController, "Driver Username", Icons.account_circle, "Please set a username"),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Driver Password", Icons.password, "Please set a password"),
              
              const SizedBox(height: 30),
              _buildSectionTitle(context, 'Vehicle details'),
              const SizedBox(height: 15),
              _buildTextField(_jeepController, "Jeep License Plate", Icons.directions_car, "Please enter license plate"),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : FilledButton(
                      onPressed: _submitForm,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Register driver'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String errorMsg) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.greyText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
      ),
      validator: (value) => (value == null || value.isEmpty) ? errorMsg : null,
    );
  }
}
