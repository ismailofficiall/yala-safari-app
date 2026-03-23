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

/// Screen responsible for allowing drivers to report park incidents.
/// This utilizes Geolocator for live coordinate tracking, ImagePicker for media,
/// Supabase Storage for remote image hoisting, and SharedPreferences mapping for offline survival.
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
    if (mounted) {
      setState(() {});
    }
  }

  String? incidentType;
  final TextEditingController noteController = TextEditingController();

  /// Holds the selected image payload in a platform-agnostic format 
  XFile? pickedFile;
  final picker = ImagePicker();

  bool loading = false;
  double? latitude;
  double? longitude;

  /// Default predefined incident flags for Safari parks
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

  /// Asynchronously retrieves the hardware GPS coordinates of the device.
  /// Handles permission checks gracefully before attempting to read lat/lng data.
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
      debugPrint("Location retrieval exception: $e");
    }
  }

  /// Triggers the native image picker overlay allowing the user to select
  /// an image via the camera interface or the local gallery.
  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        pickedFile = picked;
      });
    }
  }

  /// Validates and transmits the image blob to the Supabase Cloud Storage bucket.
  /// Converts the file into generic byte streams for universal web/mobile compatibility.
  Future<String?> uploadImage() async {
    if (pickedFile == null) return null;

    try {
      final fileName = const Uuid().v4();
      String ext = path.extension(pickedFile!.name);
      if (ext.isEmpty) ext = '.jpg'; // Fallback mapping for un-extensioned blob URLs

      final filePath = "incidents/$fileName$ext";
      final bytes = await pickedFile!.readAsBytes();

      // Transmit byte array reliably across all connected frameworks
      await SupabaseConfig.client.storage
          .from("incident-images")
          .uploadBinary(
            filePath, 
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return the public URL hook bound to the freshly uploaded file
      final imageUrl = SupabaseConfig.client.storage
          .from("incident-images")
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint("Storage blob transmission failure: $e");
      // Allow the submission hook to bypass if media layer drops out
      return "offline_failed_image";
    }
  }

  /// Compiles the telemetry and data input into a JSON report and dispatches
  /// it to the main `incidents` Postgres table in Supabase. Catches network failures.
  Future<void> submitIncident() async {
    if (incidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an incident severity type")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await getLocation();

      if (latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot verify your location. GPS signal is required.")),
          );
          setState(() => loading = false);
        }
        return;
      }

      // Yala National Park approximate bounds
      const double minLat = 6.1500;
      const double maxLat = 6.5500;
      const double minLng = 81.1000;
      const double maxLng = 81.6000;

      final double closestLat = latitude!.clamp(minLat, maxLat);
      final double closestLng = longitude!.clamp(minLng, maxLng);

      final double distanceToPerimeter = Geolocator.distanceBetween(
        latitude!,
        longitude!,
        closestLat,
        closestLng,
      );

      // 5km = 5000 meters
      if (distanceToPerimeter > 5000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot report incident: You are more than 5km away from Yala National Park."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => loading = false);
        }
        return;
      }

      String? imageUrl;
      if (pickedFile != null) {
        imageUrl = await uploadImage();
        // Nullify string if bucket rejected it to prevent bad table records
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
        "is_resolved": false,
      };

      // Perform synchronous insert across the API network
      await SupabaseConfig.client.from('incidents').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incident broadcast successfully dispatched")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Primary transmit error tracking: $e");
      
      // Implement fallback logic: Cache SOS signature via OfflineSyncService SharedPreferences queueing
      try {
        final payload = {
          "title": "${incidentType!} - ${DateTime.now().toIso8601String()}",
          "type": incidentType,
          "note": noteController.text + "\n[OFFLINE SYNCED DATA]",
          "image_url": null, // Safely discard blob binary logic for critical local caches
          "latitude": latitude ?? 0.0,
          "longitude": longitude ?? 0.0,
          "created_at": DateTime.now().toIso8601String(),
          "is_resolved": false,
        };

        await OfflineSyncService.saveOfflineIncident(payload);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No cellular signal - SOS packet locally cached for auto-syncing!"))
          );
          Navigator.pop(context);
        }
      } catch (offlineErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complete System Disconnect: $e")));
        }
      }
    }

    if (mounted) setState(() => loading = false);
  }

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
                  "Incident Classification",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: incidentType,
                  hint: const Text("Select severity parameter"),
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

                if (latitude != null && longitude != null)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(latitude!, longitude!),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.example.yala_driver_app',
                              tileProvider: CancellableNetworkTileProvider(),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(latitude!, longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 8,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95), 
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Text(
                              "This explicit location will be pinned and shared on the Live Map",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text("Acquiring GPS location to pin...", style: TextStyle(color: Colors.grey)),
                    ),
                  ),

                const SizedBox(height: 20),

                // Cross-platform rendering hook to render the XFile blob URL gracefully across Chrome
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
                      label: const Text("Capture"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text("Browse"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Field Analysis Notes",
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
                          : const Text("Transmit Report"),
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
