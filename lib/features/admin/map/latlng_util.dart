import 'package:latlong2/latlong.dart';

LatLng? parseLatLngFromRow(Map<String, dynamic> row) {
  final lat = _asDouble(row['latitude'] ?? row['lat']);
  final lng = _asDouble(row['longitude'] ?? row['lng']);
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return LatLng(lat, lng);
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
