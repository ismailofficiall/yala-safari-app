import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_theme.dart';
import '../../map/screens/live_map_screen.dart';

class IncidentFeedScreen extends StatefulWidget {
  final String driverId;
  const IncidentFeedScreen({super.key, required this.driverId});

  @override
  State<IncidentFeedScreen> createState() => _IncidentFeedScreenState();
}

class _IncidentFeedScreenState extends State<IncidentFeedScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Park Incidents'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('incidents')
            .stream(primaryKey: ['id'])
            .eq('is_resolved', false)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final incidents = snapshot.data!;
          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('All clear! No active incidents.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final item = incidents[index];
              final String title = item['title'] ?? 'Incident';
              final String type = item['type'] ?? 'Unknown';
              final String? note = item['note'];
              final String? imageUrl = item['image_url'];
              final String date = _formatDate(item['created_at']);
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getIncidentIcon(type), color: Colors.redAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '$type · $date',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (note != null && note.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(note, style: const TextStyle(fontSize: 14)),
                      ],
                      if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveMapScreen(
                                  driverId: widget.driverId,
                                  focusLocation: LatLng(item['latitude'] ?? 6.3768, item['longitude'] ?? 81.3916),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('View on Map'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case "wildlife sighting":
      case "wildlife":
        return Icons.pets;
      case "emergency":
        return Icons.warning;
      case "fire":
        return Icons.local_fire_department;
      case "road block":
      case "road_block":
        return Icons.block;
      case "vehicle breakdown":
      case "breakdown":
        return Icons.car_repair;
      default:
        return Icons.report_problem;
    }
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.length >= 16) return s.substring(0, 16).replaceFirst('T', ' ');
    return s;
  }
}
