import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/translations/app_translations.dart';

/// Wildlife Logging Interface
/// Specialized data entry screen for tracking animal sightings and behaviors.
/// Integrates with the camera and GPS for verifiable field reports.
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
  XFile? _pickedMedia;
  bool _isVideo = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _animals = ['Leopard', 'Elephant', 'Sloth Bear', 'Crocodile', 'Water Buffalo', 'Painted Stork', 'Peacock', 'Spotted Deer', 'Jungle Fowl', 'Monitor Lizard', 'Wild Boar', 'Grey Langur', 'Jackal', 'Python', 'Other'];
  final List<String> _behaviours = ['Grazing', 'Hunting', 'Moving', 'Resting', 'Aggressive', 'With Cubs/Young'];

  Future<void> _pickMedia({required bool isVideo, required ImageSource source}) async {
    final picked = isVideo ? await _picker.pickVideo(source: source) : await _picker.pickImage(source: source);
    if (picked != null) setState(() { _pickedMedia = picked; _isVideo = isVideo; });
  }

  Future<String?> _uploadMedia() async {
    if (_pickedMedia == null) return null;
    try {
      final fileName = const Uuid().v4();
      final ext = path.extension(_pickedMedia!.name).isEmpty ? (_isVideo ? '.mp4' : '.jpg') : path.extension(_pickedMedia!.name);
      final filePath = "wildlife/$fileName$ext";
      final bytes = await _pickedMedia!.readAsBytes();
      await SupabaseConfig.client.storage.from("incident-images").uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));
      return SupabaseConfig.client.storage.from("incident-images").getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Media upload failed: $e");
      return null;
    }
  }

  Future<void> _submitLog() async {
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.t('select_animal') ?? "Select animal")));
      return;
    }
    setState(() => _loading = true);
    try {
      double? lat, lng;
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        lat = pos.latitude; lng = pos.longitude;
      } catch (_) {}

      const double minLat = 6.1500, maxLat = 6.5500, minLng = 81.1000, maxLng = 81.6000;
      if (lat != null && lng != null) {
        final dist = Geolocator.distanceBetween(lat, lng, lat.clamp(minLat, maxLat), lng.clamp(minLng, maxLng));
        if (dist > 5000) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Too far from Yala Park"), backgroundColor: Colors.red));
          setState(() => _loading = false); return;
        }
      }

      String? mediaUrl = await _uploadMedia();
      await Supabase.instance.client.from('wildlife_logs').insert({
        'driver_id': widget.driverId,
        'animal': _selectedAnimal,
        'count': int.tryParse(_countCtrl.text) ?? 1,
        'behaviour': _selectedBehaviour,
        'notes': _notesCtrl.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'image_url': mediaUrl,
        'logged_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wildlife Logged!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.t('log_wildlife') ?? "Log Wildlife", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.t('animal_species') ?? "Animal Species", style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      items: _animals.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _selectedAnimal = v),
                      decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      hint: Text(AppTranslations.t('select_animal') ?? "Select"),
                    ),
                    const SizedBox(height: 20),
                    Text(AppTranslations.t('number_spotted') ?? "Count", style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(controller: _countCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppTranslations.t('behaviour') ?? "Behaviour", style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: _behaviours.map((b) => FilterChip(label: Text(b), selected: _selectedBehaviour == b, onSelected: (_) => setState(() => _selectedBehaviour = b), selectedColor: AppTheme.primaryGreen.withOpacity(0.2), checkmarkColor: AppTheme.primaryGreen)).toList()),
            const SizedBox(height: 24),
            if (_pickedMedia != null)
              Container(margin: const EdgeInsets.only(bottom: 16), height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: _isVideo ? null : DecorationImage(fit: BoxFit.cover, image: kIsWeb ? NetworkImage(_pickedMedia!.path) : FileImage(File(_pickedMedia!.path)) as ImageProvider), color: Colors.grey.shade200), child: _isVideo ? const Center(child: Icon(Icons.videocam, size: 48)) : null),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _pickMedia(isVideo: false, source: ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(AppTranslations.t('photo') ?? "Photo"))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => _pickMedia(isVideo: true, source: ImageSource.camera), icon: const Icon(Icons.videocam), label: Text(AppTranslations.t('video') ?? "Video"))),
              ],
            ),
            const SizedBox(height: 24),
            TextField(controller: _notesCtrl, maxLines: 3, decoration: InputDecoration(labelText: AppTranslations.t('notes') ?? "Notes", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedAnimal = null;
                  _selectedBehaviour = 'Grazing';
                  _pickedMedia = null;
                  _notesCtrl.clear();
                  _countCtrl.text = '1';
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Form'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitLog,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(AppTranslations.t('submit') ?? "Submit Log", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
