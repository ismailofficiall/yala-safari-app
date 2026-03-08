// lib/core/services/location_service.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_sync_service.dart';

class LocationService {
  final String databaseUrl;
  FirebaseDatabase? _db;
  Timer? _timer;
  
  // Cooldown for automatic speeding alerts (5 minutes)
  DateTime? _lastSpeedAlert;

  /// Whether periodic tracking is active
  bool get isTracking => _timer != null;

  LocationService({
    this.databaseUrl =
        "https://yala-driver-app1-default-rtdb.asia-southeast1.firebasedatabase.app/",
  });

  /// Start periodic tracking.
  /// - driverId: id to write to under /drivers/{driverId}/location
  /// - intervalSeconds: how often to write (default 10s)
  /// This method now requests permissions immediately and does a first write.
  Future<void> startTracking(
    String driverId, {
    int intervalSeconds = 10,
  }) async {
    _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseUrl);
    print('[LocationService] startTracking for $driverId, DB: $databaseUrl');

    // Ensure we have permission before starting the timer
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LocationService] location services disabled');
        // Do not start the timer if services are off.
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('[LocationService] permission request result: $permission');
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] permission deniedForever');
        return;
      }
    } catch (e) {
      print('[LocationService] permission check error: $e');
      return;
    }

    // Do an immediate send so UI updates quickly
    await sendLocationNow(driverId);
    await OfflineSyncService.syncPendingIncidents();

    // Cancel any existing timer
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      await sendLocationNow(driverId);
      
      // Attempt to sync any offline incident queues every interval
      try {
        await OfflineSyncService.syncPendingIncidents();
      } catch (_) {}
    });
  }

  /// Force a single immediate location read+write to Firebase.
  /// Useful for debugging or manual triggers.
  Future<void> sendLocationNow(String driverId) async {
    _db ??= FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseUrl);

    try {
      // Double-check services & permissions before reading
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LocationService] location services disabled (sendNow)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print(
          '[LocationService] permission request result (sendNow): $permission',
        );
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] permission deniedForever (sendNow)');
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      final payload = {
        "lat": pos.latitude,
        "lng": pos.longitude,
        "accuracy": pos.accuracy,
        "speed": pos.speed,
        "timestamp": DateTime.now().toIso8601String(),
      };

      print(
        '[LocationService] POSITION: lat=${pos.latitude}, lng=${pos.longitude}',
      );
      
      // -- SPEED AND GEOFENCE CHECK --
      // pos.speed is in meters/second. 11.11 m/s is approximately 40 km/h.
      if (pos.speed > 11.11) {
        _checkAndReportSpeeding(driverId, pos);
      }

      await _db!.ref('drivers/$driverId/location').set(payload);
    } catch (e, st) {
      print('[LocationService] sendLocationNow error: $e\n$st');
    }
  }

  Future<void> _checkAndReportSpeeding(String driverId, Position pos) async {
    if (_lastSpeedAlert != null && DateTime.now().difference(_lastSpeedAlert!).inMinutes < 5) {
      return; // Cooldown to prevent spamming
    }
    _lastSpeedAlert = DateTime.now();

    try {
      final speedKmh = (pos.speed * 3.6).toStringAsFixed(1);
      final title = "Speeding Violation";
      final note = "AUTOMATED ALERT: Jeep exceeded the park speed limit and was traveling at $speedKmh km/h. Driver ID: $driverId";

      await Supabase.instance.client.from('incidents').insert({
        "title": title,
        "type": "Other", // Categorize as Other or Speeding
        "note": note,
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "created_at": DateTime.now().toIso8601String(),
      });
      print('[LocationService] Automatically reported speeding incident!');
    } catch (e) {
      print("[LocationService] Failed to auto-report speeding: $e");
    }
  }

  /// Stop periodic tracking
  void stopTracking() {
    print('[LocationService] stopTracking');
    _timer?.cancel();
    _timer = null;
  }
}
