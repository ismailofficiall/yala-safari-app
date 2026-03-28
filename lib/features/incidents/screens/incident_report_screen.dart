import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/supabase_client.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/translations/app_translations.dart';
import '../../../core/constants/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  @override
  void initState() {
    super.initState();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    await getLocation();
    if (mounted) setState(() {});
  }

  String? incidentType;
  final TextEditingController noteController = TextEditingController();
  XFile? pickedFile;
  final picker = ImagePicker();
  bool loading = false;
  double? latitude;
  double? longitude;

  final List<String> incidentTypes = [
    "Wildlife Sighting",
    "Animal Attack",
    "Road Block",
    "Vehicle Breakdown",
    "Emergency",
    "Illegal Entry",
    "Fire",
    "Flood",
    "Other",
  ];

  Future<void> getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      latitude = pos.latitude;
      longitude = pos.longitude;
    } catch (e) {
      debugPrint("Location retrieval exception: $e");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked != null) setState(() => pickedFile = picked);
  }

  Future<String?> uploadImage() async {
    if (pickedFile == null) return null;
    try {
      final fileName = const Uuid().v4();
      String ext = path.extension(pickedFile!.name);
      if (ext.isEmpty) ext = '.jpg';
      final filePath = "incidents/$fileName$ext";
      final bytes = await pickedFile!.readAsBytes();
      await SupabaseConfig.client.storage.from("incident-images").uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));
      return SupabaseConfig.client.storage.from("incident-images").getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Storage blob transmission failure: $e");
      return "offline_failed_image";
    }
  }

  Future<void> submitIncident() async {
    if (incidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.t('select_type') ?? "Please select an incident type")));
      return;
    }

    setState(() => loading = true);

    try {
      await getLocation();
      if (latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS required for validation")));
          setState(() => loading = false);
        }
        return;
      }

      const double minLat = 6.1500, maxLat = 6.5500, minLng = 81.1000, maxLng = 81.6000;
      final double distanceToPerimeter = Geolocator.distanceBetween(latitude!, longitude!, latitude!.clamp(minLat, maxLat), longitude!.clamp(minLng, maxLng));

      if (distanceToPerimeter > 5000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Too far from Yala Park coordinates"), backgroundColor: Colors.red));
          setState(() => loading = false);
        }
        return;
      }

      String? imageUrl;
      if (pickedFile != null) {
        imageUrl = await uploadImage();
        if (imageUrl == "offline_failed_image") imageUrl = null;
      }

      final payload = {
        "title": "${incidentType!} - ${DateTime.now().toIso8601String()}",
        "type": incidentType,
        "note": noteController.text,
        "image_url": imageUrl,
        "latitude": latitude ?? 0.0,
        "longitude": longitude ?? 0.0,
        "created_at": DateTime.now().toIso8601String(),
        "is_resolved": false,
      };

      await SupabaseConfig.client.from('incidents').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.t('dispatch_success') ?? "Incident Dispatched")));
        Navigator.pop(context);
      }
    } catch (e) {
      final payload = {
        "title": "${incidentType!} - ${DateTime.now().toIso8601String()}",
        "type": incidentType,
        "note": "${noteController.text}\n[OFFLINE SYNCED]",
        "image_url": null,
        "latitude": latitude ?? 0.0,
        "longitude": longitude ?? 0.0,
        "created_at": DateTime.now().toIso8601String(),
        "is_resolved": false,
      };
      await OfflineSyncService.saveOfflineIncident(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offline - Locally Cached SOS Packet")));
        Navigator.pop(context);
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.t('report_incident') ?? "Report Incident"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.t('incident_type') ?? "Incident Classification",
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: incidentType,
                      hint: Text(AppTranslations.t('select_type') ?? "Select severity"),
                      items: incidentTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (v) => setState(() => incidentType = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (latitude != null && longitude != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(initialCenter: LatLng(latitude!, longitude!), initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                              children: [
                                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", tileProvider: CancellableNetworkTileProvider()),
                                MarkerLayer(markers: [Marker(point: LatLng(latitude!, longitude!), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                              ],
                            ),
                            Positioned(
                              bottom: 12, left: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                child: Text(AppTranslations.t('location_hint') ?? "GPS Pinned for Live Map", textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (pickedFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 220,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: kIsWeb ? NetworkImage(pickedFile!.path) : FileImage(File(pickedFile!.path)) as ImageProvider, fit: BoxFit.cover)),
              ),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(AppTranslations.t('capture') ?? "Capture"))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.gallery), icon: const Icon(Icons.photo), label: Text(AppTranslations.t('browse') ?? "Browse"))),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: AppTranslations.t('notes') ?? "Field Notes",
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : submitIncident,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(AppTranslations.t('transmit') ?? "Transmit Report", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
