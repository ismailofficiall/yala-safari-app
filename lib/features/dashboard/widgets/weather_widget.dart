import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Fetches and displays a live weather widget for Yala National Park.
/// Uses the Open-Meteo free API — no API key required.
/// Shows temperature, wind speed, and a weather condition icon.
class YalaWeatherWidget extends StatefulWidget {
  const YalaWeatherWidget({super.key});

  @override
  State<YalaWeatherWidget> createState() => _YalaWeatherWidgetState();
}

class _YalaWeatherWidgetState extends State<YalaWeatherWidget> {
  double? _tempC;
  double? _windKmh;
  int? _weatherCode;
  bool _loading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  /// Calls the Open-Meteo API for Yala National Park's GPS coordinates
  Future<void> _fetchWeather() async {
    try {
      // Yala National Park: lat=6.3768, lng=81.3916
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=6.3768&longitude=81.3916'
        '&current=temperature_2m,wind_speed_10m,weather_code'
        '&wind_speed_unit=kmh',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        if (mounted) {
          setState(() {
            _tempC = (current['temperature_2m'] as num?)?.toDouble();
            _windKmh = (current['wind_speed_10m'] as num?)?.toDouble();
            _weatherCode = (current['weather_code'] as num?)?.toInt();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _loading = false; _errorMsg = 'HTTP ${response.statusCode}'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorMsg = 'Offline'; });
    }
  }

  /// Maps the WMO weather code integer to a human-readable condition string
  String _condition(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Returns an appropriate icon for the WMO weather code
  IconData _icon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_rounded;
    if (code <= 49) return Icons.foggy;
    if (code <= 82) return Icons.umbrella_rounded;
    if (code <= 99) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: _loading
          ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : _errorMsg.isNotEmpty
              ? Row(children: [
                  const Icon(Icons.cloud_off, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(_errorMsg, style: const TextStyle(color: Colors.white70)),
                ])
              : Row(
                  children: [
                    Icon(_icon(_weatherCode ?? 0), size: 48, color: Colors.white),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yala National Park', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${_tempC?.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                        Text(_condition(_weatherCode ?? 0), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.air, color: Colors.white70, size: 18),
                        Text('${_windKmh?.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const Text('Wind speed', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
    );
  }
}
