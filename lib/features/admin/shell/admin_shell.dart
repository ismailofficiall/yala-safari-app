import 'package:flutter/material.dart';
import '../admin_theme.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_incident_screen.dart';
import '../widgets/admin_park_map.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminParkMap(),
    AdminIncidentScreen(),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
