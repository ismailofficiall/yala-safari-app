import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class OfflineSyncService {
  static const String key = 'offline_incidents';

  static Future<void> saveOfflineIncident(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(payload));
    await prefs.setStringList(key, existing);
    debugPrint("Saved incident offline. Total queued: ${existing.length}");
  }

  static Future<void> syncPendingIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList(key) ?? [];
    if (existing.isEmpty) return;

    List<String> failed = [];
    debugPrint("Syncing ${existing.length} offline incidents...");

    for (String item in existing) {
      try {
        final payload = jsonDecode(item) as Map<String, dynamic>;
        await SupabaseConfig.client.from('incidents').insert(payload);
        debugPrint("Successfully synced offline incident.");
      } catch (e) {
        debugPrint("Failed to sync offline incident, keeping in queue: $e");
        failed.add(item);
      }
    }

    await prefs.setStringList(key, failed);
  }
}
