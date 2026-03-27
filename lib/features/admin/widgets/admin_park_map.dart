import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../admin_theme.dart';
import '../map/latlng_util.dart';
import '../widgets/admin_app_bar_actions.dart';

class AdminParkMap extends StatelessWidget {
  const AdminParkMap({super.key});

  static const LatLng _yalaCenter = LatLng(6.3683, 81.5107);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        actions: const [AdminAppBarActions()],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Live map', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              'Yala National Park · fleet & open incidents',
              style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('drivers').stream(primaryKey: ['id']),
        builder: (context, driversSnap) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('incidents').stream(primaryKey: ['id']).eq('is_resolved', false),
            builder: (context, incidentsSnap) {
              if (driversSnap.hasError || incidentsSnap.hasError) {
                return Center(child: Text('Could not load map data'));
              }

              final loading = !driversSnap.hasData || !incidentsSnap.hasData;
              final drivers = driversSnap.data ?? [];
              final incidents = incidentsSnap.data ?? [];

              final jeepMarkers = <Marker>[];
              for (final d in drivers) {
                final p = parseLatLngFromRow(d);
                if (p == null) continue;
                final id = d['driver_id_code']?.toString() ?? '${d['id']}';
                final status = d['status']?.toString() ?? '';
                final color = status == 'Active' ? AdminTheme.primaryGreen : Colors.orange;
                jeepMarkers.add(_buildJeepMarker(p, id, color));
              }

              final incidentMarkers = <Marker>[];
              for (final i in incidents) {
                final p = parseLatLngFromRow(i);
                if (p == null) continue;
                incidentMarkers.add(_buildIncidentMarker(context, p, i));
              }

              final hasAnyPoint = jeepMarkers.isNotEmpty || incidentMarkers.isNotEmpty;

              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _yalaCenter,
                      initialZoom: 11.5,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      // Constrain Admin view to Yala bounds
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(
                          const LatLng(6.1500, 81.1000), 
                          const LatLng(6.5500, 81.6000), 
                        ),
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.yala_driver_app_1',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      MarkerLayer(markers: jeepMarkers),
                      MarkerLayer(markers: incidentMarkers),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (loading)
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x88FFFFFF), child: Center(child: CircularProgressIndicator())),
                    ),
                  if (!loading && !hasAnyPoint)
                    Positioned(
                      left: 12, right: 12, top: 12,
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        color: AdminTheme.surface,
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No GPS pins yet. When drivers send latitude & longitude, jeeps and incidents appear here.',
                            style: TextStyle(fontSize: 13, height: 1.4, color: AdminTheme.darkText, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12, right: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    child: const _MapLegend(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static Marker _buildJeepMarker(LatLng point, String id, Color color) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: 'Jeep $id',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(Icons.directions_car_rounded, color: color, size: 24),
        ),
      ),
    );
  }

  static Marker _buildIncidentMarker(BuildContext context, LatLng point, Map<String, dynamic> item) {
    final String type = item['type']?.toString() ?? 'Incident';
    
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AdminTheme.surface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  if (item['note'] != null && '${item['note']}'.trim().isNotEmpty)
                    Text('Driver Note:\n${item['note']}'),
                  const SizedBox(height: 10),
                  if (item['image_url'] != null && '${item['image_url']}'.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${item['image_url']}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => const Text("Failed to load image", style: TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: Tooltip(
          message: type,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _dot(AdminTheme.primaryGreen, 'Jeep (active)'),
            _dot(Colors.orange, 'Jeep (other)'),
            _dot(Colors.red, 'Incident'),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.greyText, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
