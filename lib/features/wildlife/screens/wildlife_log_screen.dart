import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_theme.dart';

/// Screen allowing drivers to log wildlife encounters separately from incidents.
/// Records the animal species, count, behaviour, GPS stub, and timestamp in Supabase.
class WildlifeLogScreen extends StatefulWidget {
  final String driverId;
  const WildlifeLogScreen({super.key, required this.driverId});

  @override
  State<WildlifeLogScreen> createState() => _WildlifeLogScreenState();
}

class _WildlifeLogScreenState extends State<WildlifeLogScreen> {
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _countCtrl = TextEditingController(text: '1');
  String? _selectedAnimal;
  String _selectedBehaviour = 'Grazing';
  bool _loading = false;

  /// Categorical list of animals commonly spotted inside Yala
  final List<String> _animals = [
    'Leopard', 'Elephant', 'Sloth Bear', 'Crocodile', 'Water Buffalo',
    'Painted Stork', 'Peacock', 'Spotted Deer', 'Jungle Fowl', 'Monitor Lizard',
    'Wild Boar', 'Grey Langur', 'Jackal', 'Python', 'Other',
  ];

  final List<String> _behaviours = [
    'Grazing', 'Hunting', 'Moving', 'Resting', 'Aggressive', 'With Cubs/Young',
  ];

  /// Submits the wildlife sighting record to the `wildlife_logs` table in Supabase
  Future<void> _submitLog() async {
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an animal species")));
      return;
    }

    setState(() => _loading = true);

    try {
      // Attempt to retrieve current GPS coordinates for accurate mapping
      double? lat, lng;
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        debugPrint('GPS failed for wildlife log: $e');
      }

      // Insert new row into the wildlife_logs Postgres table
      await Supabase.instance.client.from('wildlife_logs').insert({
        'driver_id': widget.driverId,
        'animal': _selectedAnimal,
        'count': int.tryParse(_countCtrl.text) ?? 1,
        'behaviour': _selectedBehaviour,
        'notes': _notesCtrl.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'logged_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wildlife encounter logged successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to log: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Log Wildlife Encounter", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Record a wildlife encounter for park biodiversity tracking",
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Animal Species", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            // Dropdown to choose from predefined Yala fauna list
            DropdownButtonFormField<String>(
              value: _selectedAnimal,
              hint: const Text("Select animal"),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _animals.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => _selectedAnimal = v),
            ),
            const SizedBox(height: 20),

            const Text("Number Spotted", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "1"),
            ),
            const SizedBox(height: 20),

            const Text("Behaviour Observed", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            // Scrollable behaviour selection chips
            Wrap(
              spacing: 8,
              children: _behaviours.map((b) {
                final selected = _selectedBehaviour == b;
                return FilterChip(
                  label: Text(b),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedBehaviour = b),
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
                  checkmarkColor: AppTheme.primaryGreen,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text("Additional Notes (Optional)", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Describe the sighting in detail..."),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text("Submit Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
