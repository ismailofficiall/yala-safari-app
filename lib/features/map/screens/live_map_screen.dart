// lib/features/map/screens/live_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveMapScreen extends StatefulWidget {
  final String driverId;
  final String databaseUrl;
  final LatLng? focusLocation;

  const LiveMapScreen({
    super.key,
    required this.driverId,
    this.focusLocation,
    this.databaseUrl =
        "https://yala-driver-app1-default-rtdb.asia-southeast1.firebasedatabase.app/",
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  late final FirebaseDatabase _db;

  StreamSubscription<DatabaseEvent>? _driversAddedSub;
  StreamSubscription<DatabaseEvent>? _driversChangedSub;
  StreamSubscription<DatabaseEvent>? _driversRemovedSub;
  StreamSubscription<DatabaseEvent>? _ownLocationSub;

  // Supabase incidents stream subscription
  StreamSubscription<dynamic>? _incidentSub;

  LatLng? _ownLocation;
  final Map<String, LatLng> _otherJeeps = {};
  final List<_Zone> _restrictedZones = [];

  // Incident list (from Supabase)
  final List<_Incident> _incidents = [];

  bool _hasShownZoneWarning = false;
  String? _currentZoneId;
  bool _hasCenteredOnce = false;

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: widget.databaseUrl);

    _listenRestrictedZones();
    _listenOtherJeeps();
    _listenOwnLocation();

    _listenIncidents();
  }

  @override
  void dispose() {
    _driversAddedSub?.cancel();
    _driversChangedSub?.cancel();
    _driversRemovedSub?.cancel();
    _ownLocationSub?.cancel();
    _incidentSub?.cancel();
    super.dispose();
  }

  // ---------------- INCIDENT LISTENER (Supabase) ----------------
  void _listenIncidents() {
    try {
      final client = Supabase.instance.client;
      _incidentSub = client
          .from('incidents')
          .stream(primaryKey: ['id'])
          .listen(
            (event) {
              try {
                // event usually is List<Map<String, dynamic>>
                final rows = (event as List).cast<Map<String, dynamic>>();
                final list = rows.map((row) {
                  double lat = 0.0, lng = 0.0;
                  try {
                    lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
                    lng = (row['longitude'] as num?)?.toDouble() ?? 0.0;
                  } catch (_) {}
                  return _Incident(
                    id: row['id']?.toString() ?? UniqueKey().toString(),
                    type: (row['type'] as String?) ?? 'unknown',
                    note: row['note'] as String?,
                    imageUrl: row['image_url'] as String?,
                    lat: lat,
                    lng: lng,
                  );
                }).toList();

                setState(() {
                  _incidents
                    ..clear()
                    ..addAll(list);
                });
              } catch (e, st) {
                debugPrint('[Incidents] parse error: $e\n$st');
              }
            },
            onError: (err) {
              debugPrint('[Incidents] stream error: $err');
            },
          );
    } catch (e, st) {
      debugPrint('[Incidents] listen failed: $e\n$st');
    }
  }

  // ---------------- Firebase Listeners ----------------
  void _listenOtherJeeps() {
    final ref = _db.ref('drivers');

    _driversAddedSub = ref.onChildAdded.listen((event) {
      final id = event.snapshot.key;
      final loc = event.snapshot.child('location').value;
      if (id == null || loc == null) return;
      _updateJeepFromSnapshot(id, event.snapshot);
    });

    _driversChangedSub = ref.onChildChanged.listen((event) {
      final id = event.snapshot.key;
      if (id == null) return;
      _updateJeepFromSnapshot(id, event.snapshot);
    });

    _driversRemovedSub = ref.onChildRemoved.listen((event) {
      final id = event.snapshot.key;
      if (id == null) return;
      setState(() {
        _otherJeeps.remove(id);
      });
    });
  }

  void _updateJeepFromSnapshot(String id, DataSnapshot snapshot) {
    final locSnap = snapshot.child('location');
    if (!locSnap.exists) return;
    final data = locSnap.value as Map<Object?, Object?>?;
    if (data == null) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    if (id == widget.driverId) {
      setState(() {
        _ownLocation = LatLng(lat, lng);
      });
      _checkRestrictedZones(LatLng(lat, lng));
      _centerMapOnce();
      return;
    }

    setState(() {
      _otherJeeps[id] = LatLng(lat, lng);
    });
  }

  void _listenOwnLocation() {
    final ref = _db.ref('drivers/${widget.driverId}/location');

    _ownLocationSub = ref.onValue.listen(
      (event) {
        final v = event.snapshot.value as Map<Object?, Object?>?;
        if (v == null) return;
        final lat = (v['lat'] as num?)?.toDouble();
        final lng = (v['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;

        setState(() {
          _ownLocation = LatLng(lat, lng);
        });
        _checkRestrictedZones(LatLng(lat, lng));
        _centerMapOnce();
      },
      onError: (err) {
        debugPrint('[MapScreen] ownLocationSub error: $err');
      },
    );
  }

  // ---------------- Restricted zones ----------------
  void _listenRestrictedZones() async {
    try {
      final ref = _db.ref('restricted_zones');
      final snap = await ref.get();
      if (snap.exists) {
        final map = snap.value as Map<Object?, Object?>;
        map.forEach((key, value) {
          final v = value as Map<Object?, Object?>?;
          if (v == null) return;
          final poly = <LatLng>[];
          final rawPoly = v['polygon'] as List<dynamic>?;
          if (rawPoly != null) {
            for (final p in rawPoly) {
              final m = p as Map<Object?, Object?>;
              final lat = (m['lat'] as num?)?.toDouble();
              final lng = (m['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) poly.add(LatLng(lat, lng));
            }
          }
          final zone = _Zone(
            id: key.toString(),
            name: v['name']?.toString() ?? 'Zone',
            polygon: poly,
            active: (v['active'] ?? true) == true,
          );
          _restrictedZones.add(zone);
        });
        setState(() {});
      }

      // subscribe to changes
      ref.onChildChanged.listen((event) {
        _restrictedZones.clear();
        _listenRestrictedZones();
      });
    } catch (e, st) {
      debugPrint('[Zones] listen error: $e\n$st');
    }
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  void _checkRestrictedZones(LatLng location) {
    for (final z in _restrictedZones.where((z) => z.active)) {
      final inside = _pointInPolygon(location, z.polygon);
      if (inside && _currentZoneId != z.id) {
        _currentZoneId = z.id;
        _showRestrictedZoneWarning(z);
        return;
      } else if (!inside && _currentZoneId == z.id) {
        _currentZoneId = null;
        _hasShownZoneWarning = false;
      }
    }
  }

  void _showRestrictedZoneWarning(_Zone zone) {
    if (_hasShownZoneWarning) return;
    _hasShownZoneWarning = true;
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restricted Zone'),
        content: Text(
          'You entered restricted area: ${zone.name}. Please stop and follow rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------------- INCIDENT MARKERS ----------------
  List<Marker> _buildIncidentMarkers() {
    final markers = <Marker>[];

    for (final i in _incidents) {
      // skip invalid coords
      if (i.lat == 0.0 && i.lng == 0.0) continue;

      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(i.lat, i.lng),
          child: GestureDetector(
            onTap: () => _showIncidentPopup(i),
            child: Icon(_getIncidentIcon(i.type), color: Colors.red, size: 30),
          ),
        ),
      );
    }

    return markers;
  }

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case "wildlife":
      case "wildlife sighting":
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

  void _showIncidentPopup(_Incident i) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i.type.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (i.note != null) Text(i.note!),
            const SizedBox(height: 10),
            if (i.imageUrl != null)
              Image.network(
                i.imageUrl!,
                width: double.infinity,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- Map helpers ----------------
  void _centerMapOnce() {
    if (!_isMapReady || _hasCenteredOnce) return;
    
    try {
      if (widget.focusLocation != null) {
        _mapController.move(widget.focusLocation!, 15.0);
        _hasCenteredOnce = true;
      } else if (_ownLocation != null) {
        _mapController.move(_ownLocation!, 15.0);
        _hasCenteredOnce = true;
      }
    } catch (_) {}
  }

  Future<void> _recenterToOwnLocation() async {
    if (_ownLocation != null) {
      _mapController.move(_ownLocation!, 15);
      return;
    }
    try {
      final p =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(p.latitude, p.longitude), 15);
    } catch (_) {}
  }

  // ---------------- Markers ----------------
  List<Marker> _buildJeepMarkers() {
    final markers = <Marker>[];

    if (_ownLocation != null) {
      markers.add(
        Marker(
          width: 100,
          height: 100,
          point: _ownLocation!,
          child: const _OwnMarkerWidget(),
        ),
      );
    }

    _otherJeeps.forEach((id, latlng) {
      markers.add(
        Marker(
          width: 50,
          height: 50,
          point: latlng,
          child: _OtherJeepMarker(driverId: id),
        ),
      );
    });

    return markers;
  }


  @override
  Widget build(BuildContext context) {
    // Center logic prioritizes focusLocation (like an incident), then ownLocation, then park default
    final center = widget.focusLocation ?? _ownLocation ?? const LatLng(6.3768, 81.3916);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Map (Driver)')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.0,
          maxZoom: 18.0,
          minZoom: 10.0,
          onMapReady: () {
            _isMapReady = true;
            _centerMapOnce();
            if (_ownLocation == null) {
              _recenterToOwnLocation();
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.yala_driver_app',
            tileProvider: CancellableNetworkTileProvider(),
          ),
          MarkerLayer(
            markers: [..._buildJeepMarkers(), ..._buildIncidentMarkers()],
          ),
          PolygonLayer(
            polygons: _restrictedZones.map((z) {
              return Polygon(
                points: z.polygon,
                borderStrokeWidth: 2,
                color: z.active
                    ? Colors.red.withValues(alpha: 0.18)
                    : Colors.grey.withValues(alpha: 0.10),
                borderColor: z.active ? Colors.red : Colors.grey,
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StyledMapButton(
            icon: Icons.my_location_rounded,
            onTap: _recenterToOwnLocation,
            color: const Color(0xFF1B5E20), // Primary Green
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                _StyledMapButton(
                  icon: Icons.add_rounded,
                  transparent: true,
                  onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  color: Colors.black87,
                ),
                Container(height: 1, width: 30, color: Colors.black12),
                _StyledMapButton(
                  icon: Icons.remove_rounded,
                  transparent: true,
                  onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  color: Colors.black87,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool transparent;

  const _StyledMapButton({required this.icon, required this.onTap, required this.color, this.transparent = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: transparent ? Colors.transparent : Colors.white,
      shape: transparent ? null : const CircleBorder(),
      borderRadius: transparent ? BorderRadius.circular(20) : null,
      elevation: transparent ? 0 : 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: transparent ? null : const CircleBorder(),
        borderRadius: transparent ? BorderRadius.circular(20) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}

// ---------------- INCIDENT MODEL ----------------

class _Incident {
  final String id;
  final String type;
  final String? note;
  final String? imageUrl;
  final double lat;
  final double lng;

  _Incident({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
    this.note,
    this.imageUrl,
  });
}

// ---------------- Marker Widgets ----------------

class _OwnMarkerWidget extends StatelessWidget {
  const _OwnMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20), // AppTheme.primaryGreen
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _OtherJeepMarker extends StatelessWidget {
  final String driverId;
  const _OtherJeepMarker({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8954F).withValues(alpha: 0.15), // AppTheme.accentGold
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFFB8954F), size: 36),
                ),
                const SizedBox(height: 16),
                const Text("Safari Driver", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("ID: $driverId", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text("Acknowledge"),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB8954F), // accentGold
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: const Center(
          child: Icon(Icons.person_pin, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ---------------- Restricted Zone Model ----------------

class _Zone {
  final String id;
  final String name;
  final List<LatLng> polygon;
  final bool active;

  _Zone({
    required this.id,
    required this.name,
    required this.polygon,
    required this.active,
  });
}
