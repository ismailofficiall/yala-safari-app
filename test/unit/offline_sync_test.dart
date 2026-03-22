import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yala_driver_app_1/core/services/offline_sync_service.dart';

void main() {
  group('OfflineSyncService Unit Tests', () {
    const testQueueKey = 'offline_incidents';

    setUp(() {
      // Mock SharedPreferences for the in-memory testing environment
      SharedPreferences.setMockInitialValues({});
    });

    test('saveOfflineIncident stores a JSON stringified map safely to SharedPreferences', () async {
      final payload = {
        'title': 'Elephant blocking road',
        'latitude': 6.3,
        'longitude': 81.4,
        'type': 'Elephant',
      };
      
      await OfflineSyncService.saveOfflineIncident(payload);

      final prefs = await SharedPreferences.getInstance();
      final List<String>? queue = prefs.getStringList(testQueueKey);

      expect(queue, isNotNull, reason: "The hardware queue should exist");
      expect(queue!.length, 1, reason: "Queue should contain exactly 1 serialized element");

      final incidentData = jsonDecode(queue.first) as Map<String, dynamic>;
      expect(incidentData['title'], 'Elephant blocking road');
      expect(incidentData['latitude'], 6.3);
      expect(incidentData['longitude'], 81.4);
    });

    test('saveOfflineIncident appends rather than overwriting existing items', () async {
      await OfflineSyncService.saveOfflineIncident({'title': 'Flat Tire'});
      await OfflineSyncService.saveOfflineIncident({'title': 'Spotted Leopard'});

      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(testQueueKey)!;

      expect(queue.length, 2, reason: "Both incidents should have safely appended to the array");
      
      final first = jsonDecode(queue[0]);
      final second = jsonDecode(queue[1]);
      
      expect(first['title'], 'Flat Tire');
      expect(second['title'], 'Spotted Leopard');
    });

    test('syncPendingIncidents fast-fails when device storage is completely empty', () async {
      // Empty storage scenario
      SharedPreferences.setMockInitialValues({});
      
      // Should instantly return without errors
      await OfflineSyncService.syncPendingIncidents();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(testQueueKey), isNull);
    });
  });
}
