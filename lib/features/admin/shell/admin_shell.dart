import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_incident_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/admin_audit_log_screen.dart';
import '../widgets/admin_park_map.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  RealtimeChannel? _incidentChannel;

  @override
  void initState() {
    super.initState();
    _listenForEmergency();
  }

  void _listenForEmergency() {
    _incidentChannel = Supabase.instance.client.channel('public:incidents').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'incidents',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord['type'] == 'Emergency' || newRecord['title']?.contains('SOS') == true) {
          _showGlobalSosAlert(newRecord);
        }
      },
    )..subscribe();
  }

  void _showGlobalSosAlert(Map<String, dynamic> record) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text("SOS SYSTEM ALERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "A PANIC BUTTON WAS TRIGGERED!\n\nDetails:\n${record['title']}\n\nNotes:\n${record['note'] ?? 'No extra notes provided in initial panic'}",
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red[900]),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _selectedIndex = 1); // Switch to Admin Live Map
            },
            icon: const Icon(Icons.map_rounded),
            label: const Text("RESPOND ON MAP", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _incidentChannel?.unsubscribe();
    super.dispose();
  }

  /// All top-level admin pages accessible via the bottom navigation bar
  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminParkMap(),
    AdminIncidentScreen(),
    AdminAnalyticsScreen(),
    AdminAuditLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.lightTheme,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(26),
            color: AdminTheme.surface,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                backgroundColor: AdminTheme.surface,
                elevation: 0,
                height: 68,
                indicatorColor: AdminTheme.primaryGreen.withValues(alpha: 0.14),
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded),
                    label: 'Live Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.warning_amber_outlined),
                    selectedIcon: Icon(Icons.warning_rounded),
                    label: 'Incidents',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history_rounded),
                    label: 'Audit Log',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
