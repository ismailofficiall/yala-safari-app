import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/translations/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen responsible for displaying specific data bound to the logged-in driver.
/// It reads the driver ID passed via routing, and fetches their realtime 
/// telemetry and profile records directly from the Postgres database.
class DriverProfileScreen extends StatefulWidget {
  final String driverId;

  const DriverProfileScreen({super.key, required this.driverId});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  /// Defines a nullable dictionary mapping to catch JSON returns from Supabase
  Map<String, dynamic>? driverData;
  
  /// Boolean flag controlling the rendering state of the loading overlay
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize async data retrieval immediately upon widget mounting
    _fetchProfile();
  }

  /// Asynchronously queries the `drivers` table in Supabase.
  /// Uses a relational row match `eq` against the driver ID integer.
  Future<void> _fetchProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq('id', int.parse(widget.driverId))
          .maybeSingle();

      if (mounted) {
        // Trigger a synchronous frame rebuild when data securely arrives
        setState(() {
          driverData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Database relational fetch query failed: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Evaluates SharedPreferences cache to enforce the mandatory 14-day profile lockout rule.
  /// If permitted, renders a modal dialog mutating the `driver_name` and `jeep_id` directly in Supabase.
  Future<void> _handleProfileEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastEditStr = prefs.getString('last_profile_edit_${widget.driverId}');
    
    // Enforce 14-day cooldown lock policy
    if (lastEditStr != null) {
      final lastEdit = DateTime.parse(lastEditStr);
      final difference = DateTime.now().difference(lastEdit).inDays;
      if (difference < 14) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile editing locked. Security policy limits changes to once every 14 days. ($difference/14 days elapsed)"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    
    final nameCtrl = TextEditingController(text: driverData?['driver_name']);
    final jeepCtrl = TextEditingController(text: driverData?['jeep_id']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Driver Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("WARNING: You can only edit your profile once every 14 days.", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: jeepCtrl, decoration: const InputDecoration(labelText: "Jeep License Plate")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              try {
                // Synchronously mutate remote Postgres row
                await Supabase.instance.client
                    .from('drivers')
                    .update({
                      'driver_name': nameCtrl.text.trim(),
                      'jeep_id': jeepCtrl.text.trim()
                    })
                    .eq('id', int.parse(widget.driverId));
                
                // Burn the 14-day cooldown timestamp into local NVRAM
                await prefs.setString('last_profile_edit_${widget.driverId}', DateTime.now().toIso8601String());
                
                await _fetchProfile(); // Refresh UI dynamically
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
              } catch (e) {
                 if (mounted) {
                   setState(() => isLoading = false);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Initial State: Waiting for server response
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    // Error State: Database query returned zero matches
    if (driverData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: Text("Profile data not found.")),
      );
    }

    // Final State: Validly bind parsed Postgres row data into strong string constants
    final String name = driverData?['driver_name'] ?? 'Unknown Driver';
    final String nic = driverData?['driver_id_code'] ?? 'N/A';
    final String jeepId = driverData?['jeep_id'] ?? 'N/A';
    final String status = driverData?['status'] ?? 'Active';
    final double rating = (driverData?['rating'] ?? 5.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          // Edit Profile trigger button
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
            onPressed: () => _handleProfileEdit(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Generic Profile Picture Avatar element
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
            const SizedBox(height: 8),

            // Dynamically colored status tag container mapping logic to string states
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == 'Active' ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Language Selection Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('App Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  DropdownButton<String>(
                    value: AppTranslations.currentLang,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                      DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          AppTranslations.currentLang = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Language fully updating on next screen navigation."),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Performance metrics grouped inside a custom layout card
            _buildInfoCard(
              context,
              title: "Performance",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Driver Rating", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.accentGold, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1), // Lock decimal threshold for UX safety
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Administrative credential elements grouped inside custom layout card
            _buildInfoCard(
              context,
              title: "Credentials",
              child: Column(
                children: [
                  _infoRow("Driver ID (NIC)", nic),
                  const Divider(height: 24),
                  _infoRow("Assigned Jeep", jeepId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Private helper UI widget compiling repetitive container styling mechanics.
  /// Takes a widget child interface so the developer can cleanly nest row columns.
  Widget _buildInfoCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.greyText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Specialized micro-widget layout handling identical row label/value relationships
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkText)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
      ],
    );
  }
}
