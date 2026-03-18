import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../../../core/services/offline_sync_service.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
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

  // ---------------- LOCATION ----------------

  Future<void> getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      latitude = pos.latitude;
      longitude = pos.longitude;
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // ---------------- IMAGE PICKER ----------------

  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        pickedFile = picked;
      });
    }
  }

  // ---------------- IMAGE UPLOAD ----------------

  Future<String?> uploadImage() async {
    if (pickedFile == null) return null;

    try {
      final fileName = const Uuid().v4();
      
      String ext = path.extension(pickedFile!.name);
      if (ext.isEmpty) ext = '.jpg';

      final filePath = "incidents/$fileName$ext";
      
      final bytes = await pickedFile!.readAsBytes();

      await SupabaseConfig.client.storage
          .from("incident-images")
          .uploadBinary(
            filePath, 
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = SupabaseConfig.client.storage
          .from("incident-images")
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint("Image upload error: $e");
      // Allow proceeding without image if it fails
      return "offline_failed_image";
    }
  }

  // ---------------- SUBMIT INCIDENT ----------------

  Future<void> submitIncident() async {
    if (incidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an incident type")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await getLocation();

      String? imageUrl;
      if (pickedFile != null) {
        imageUrl = await uploadImage();
        if (imageUrl == "offline_failed_image") imageUrl = null;
      }

      final title = "${incidentType!} - ${DateTime.now().toIso8601String()}";
      
      final payload = {
        "title": title,
        "type": incidentType,
        "note": noteController.text,
        "image_url": imageUrl,
        "latitude": latitude ?? 0.0,
        "longitude": longitude ?? 0.0,
        "created_at": DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client.from('incidents').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incident Reported Successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Submit error (going offline mode): $e");
      
      // OFFLINE QUEUE logic
      try {
        final payload = {
          "title": "${incidentType!} - ${DateTime.now().toIso8601String()}",
          "type": incidentType,
          "note": noteController.text + "\n[OFFLINE SYNCED DATA]",
          "image_url": null, // Can't easily cache binary locally, ignore image for offline S.O.S
          "latitude": latitude ?? 0.0,
          "longitude": longitude ?? 0.0,
          "created_at": DateTime.now().toIso8601String(),
        };

        await OfflineSyncService.saveOfflineIncident(payload);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No Internet - Emergency saved locally for auto-sync!"))
          );
          Navigator.pop(context);
        }
      } catch (offlineErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Critical Error: $e")));
        }
      }
    }

    if (mounted) setState(() => loading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Incident"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Incident Type",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: incidentType,

                  hint: const Text("Select incident type"),

                  items: incidentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      incidentType = value;
                    });
                  },

                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                if (pickedFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(pickedFile!.path, height: 200, fit: BoxFit.cover)
                        : Image.file(File(pickedFile!.path), height: 200, fit: BoxFit.cover),
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text("Gallery"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: noteController,

                  maxLines: 4,

                  decoration: const InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: loading ? null : submitIncident,

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Incident"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
