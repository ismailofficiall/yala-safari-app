import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_client.dart';

/// Service class dedicated to handling offline data persistence.
/// Critical for Safari park operations where drivers frequently traverse 
/// areas with zero cellular connectivity (e.g. deep inside Yala National Park).
/// Implements a FIFO queue using local persistence and a retry loop.
class OfflineSyncService {
  /// Defines the key used to store the serialized JSON queue inside SQLite/UserDefaults
  static const String key = 'offline_incidents';
  static bool _isSyncing = false;

  /// Serializes an incident payload into a JSON string and pushes it onto
  /// the local hardware SharedPreferences buffer.
  /// 
  /// @param payload The raw dictionary map generated from the IncidentReportScreen.
  static Future<void> saveOfflineIncident(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve the existing queue or initialize an empty state list
    List<String> existing = prefs.getStringList(key) ?? [];
    
    // Append the newly stringified JSON bundle directly to the queue
    existing.add(jsonEncode(payload));
    
    // Overwrite the hardware memory with the newly extended list
    await prefs.setStringList(key, existing);
    debugPrint("Saved incident offline. Total queued: ${existing.length}");
  }

  /// Iterates over the local hardware queue and systematically attempts to push
  /// each serialized packet to the remote Supabase Postgres table.
  /// Safe to call periodically as it dynamically handles network rejection natively.
  static Future<void> syncPendingIncidents() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList(key) ?? [];
    
    // Fast-fail if there is no data to process, saving CPU cycles
    if (existing.isEmpty) return;

    // Temporal buffer to catch any payloads that fail to transmit during this specific loop
    List<String> failed = [];
    debugPrint("Syncing ${existing.length} offline incidents...");

    for (String item in existing) {
      try {
        // Deserialize the cached string back into an executable Dart Map object
        final payload = jsonDecode(item) as Map<String, dynamic>;
        
        // Asynchronously insert the data payload to the cloud
        await SupabaseConfig.client.from('incidents').insert(payload);
        debugPrint("Successfully synced offline incident.");
      } catch (e) {
        // If transmission fails (still no internet), push it back onto the fail buffer
        if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          debugPrint("[OfflineSync] Network unavailable. Retrying in next cycle.");
        } else {
          debugPrint("[OfflineSync] Payload rejection or DB error: $e");
        }
        failed.add(item);
      }
    }

    // Overwrite the hardware memory. If all succeeded, `failed` is purely empty.
    await prefs.setStringList(key, failed);
    _isSyncing = false;
  }
}
