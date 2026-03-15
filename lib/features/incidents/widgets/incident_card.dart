import 'package:flutter/material.dart';
import '../../map/screens/live_map_screen.dart';
import 'package:latlong2/latlong.dart';

class IncidentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String driverId;
  final String title;
  final String type;
  final String date;
  final IconData icon;

  const IncidentCard({
    super.key,
    required this.item,
    required this.driverId,
    required this.title,
    required this.type,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final String? note = item['note'];
    final String? imageUrl = item['image_url'];

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '$type · $date',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                note,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) =>
                      const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveMapScreen(
                        driverId: driverId,
                        focusLocation: LatLng(
                          item['latitude'] ?? 6.3768,
                          item['longitude'] ?? 81.3916,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('Locate on Map'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
