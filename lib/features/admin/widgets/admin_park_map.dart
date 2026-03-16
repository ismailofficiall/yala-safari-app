import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
                final title = i['title']?.toString() ?? 'Incident';
                incidentMarkers.add(_buildIncidentMarker(p, title));
              }

              final hasAnyPoint = jeepMarkers.isNotEmpty || incidentMarkers.isNotEmpty;

              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _yalaCenter,
                      initialZoom: 11.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.yala_driver_app_1',
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

  static Marker _buildIncidentMarker(LatLng point, String type) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: Tooltip(
        message: type,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
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
