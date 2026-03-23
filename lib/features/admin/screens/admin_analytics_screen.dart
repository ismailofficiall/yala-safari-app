import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin_theme.dart';
import '../widgets/admin_app_bar_actions.dart';
import '../services/pdf_report_service.dart';

/// Admin performance analytics screen showing:
/// - Bar chart of incident counts per day (last 7 days)
/// - Bar chart of incidents by type
/// - Top performing drivers by rating
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Fetches both incident and driver data from Supabase for chart computation
  Future<void> _loadData() async {
    try {
      final incidents = await _supabase.from('incidents').select().order('created_at', ascending: false);
      final drivers = await _supabase.from('drivers').select().order('rating', ascending: false);
      if (mounted) {
        setState(() {
          _incidents = List<Map<String, dynamic>>.from(incidents);
          _drivers = List<Map<String, dynamic>>.from(drivers);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Groups incidents by day for the last 7 days and returns counts per day label
  Map<String, int> _incidentsByDay() {
    final Map<String, int> dayCounts = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.day}/${day.month}';
      dayCounts[key] = 0;
    }

    for (final incident in _incidents) {
      try {
        final dt = DateTime.parse(incident['created_at'] as String);
        final key = '${dt.day}/${dt.month}';
        if (dayCounts.containsKey(key)) {
          dayCounts[key] = (dayCounts[key] ?? 0) + 1;
        }
      } catch (_) {}
    }
    return dayCounts;
  }

  /// Aggregates incident counts by type for the type-frequency chart
  Map<String, int> _incidentsByType() {
    final Map<String, int> typeCounts = {};
    for (final i in _incidents) {
      final type = i['type']?.toString() ?? 'Other';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    return typeCounts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        actions: const [AdminAppBarActions()],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('Fleet performance & incident trends', style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'analytics_export_pdf_fab',
        onPressed: _incidents.isEmpty && _drivers.isEmpty
            ? null
            : () => PdfReportService.generateWeeklyReport(incidents: _incidents, drivers: _drivers),
        backgroundColor: AdminTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Export to PDF', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.12,
                    child: SizedBox.expand(
                      child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
                    ),
                  ),
                  SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary stats row
                    Row(
                      children: [
                        _statCard('Total Incidents', '${_incidents.length}', AdminTheme.primaryGreen),
                        const SizedBox(width: 12),
                        _statCard('Active Drivers', '${_drivers.where((d) => d['status'] == 'Active').length}', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ---- Bar chart: Incidents last 7 days ----
                    Text('Incidents — Last 7 Days', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _incidents7DaysChart(),
                    const SizedBox(height: 28),

                    // ---- Bar chart: Incidents by type ----
                    Text('Incidents by Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _incidentsByTypeChart(),
                    const SizedBox(height: 28),

                    // ---- Driver rating leaderboard ----
                    Text('Driver Performance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    ..._drivers.take(5).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final d = entry.value;
                      final double rating = (d['rating'] is num) ? (d['rating'] as num).toDouble() : 5.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AdminTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              // Rank number
                              SizedBox(
                                width: 36,
                                child: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AdminTheme.greyText)),
                              ),
                              Expanded(child: Text('${d['driver_name'] ?? 'Driver'}', style: const TextStyle(fontWeight: FontWeight.w700))),
                              // Horizontal rating bar using LinearProgressIndicator
                              SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(
                                  value: rating / 5.0,
                                  color: rating >= 4 ? AdminTheme.primaryGreen : rating >= 3 ? Colors.orange : Colors.red,
                                  backgroundColor: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const Icon(Icons.star_rounded, color: AdminTheme.accentGold, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
              ],
            ),
            ),
    );
  }

  /// Builds the 7-day incident frequency bar chart using fl_chart BarChartData
  Widget _incidents7DaysChart() {
    final data = _incidentsByDay();
    final keys = data.keys.toList();
    final maxY = (data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b)).toDouble() + 1;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: keys.asMap().entries.map((entry) {
            final idx = entry.key;
            final key = entry.value;
            return BarChartGroupData(x: idx, barRods: [
              BarChartRodData(
                toY: (data[key] ?? 0).toDouble(),
                color: AdminTheme.primaryGreen,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ]);
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(keys[v.toInt()], style: const TextStyle(fontSize: 10, color: AdminTheme.greyText)),
                ),
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  /// Builds a horizontal bar chart of incidents grouped by type
  Widget _incidentsByTypeChart() {
    final data = _incidentsByType();
    if (data.isEmpty) return const Text("No incident data available.", style: TextStyle(color: AdminTheme.greyText));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: data.entries.map((entry) {
          final maxCount = data.values.reduce((a, b) => a > b ? a : b);
          final ratio = entry.value / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                    color: _typeColor(entry.key),
                    backgroundColor: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'emergency': return Colors.red;
      case 'wildlife sighting': return AdminTheme.primaryGreen;
      case 'vehicle breakdown': return Colors.orange;
      case 'road block': return Colors.indigo;
      default: return Colors.blueGrey;
    }
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AdminTheme.greyText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
