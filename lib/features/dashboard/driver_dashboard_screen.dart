// lib/features/dashboard/driver_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../features/map/screens/live_map_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../features/incidents/screens/incident_report_screen.dart';
import '../../../core/translations/app_translations.dart';
import '../../../features/messages/screens/message_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../auth/screens/login_screen.dart';
import '../profile/screens/driver_profile_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String driverId;
  final String jeepId;
  final String block;

  const DriverDashboardScreen({
    super.key,
    required this.driverId,
    this.jeepId = 'Unknown',
    this.block = 'Unknown',
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _location_service_start();
  }

  void _location_service_start() {
    if (widget.driverId.isEmpty) return;
    try {
      _locationService.startTracking(widget.driverId);
    } catch (e, st) {
      debugPrint('[Dashboard] startTracking error: $e\n$st');
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  void _logout() {
    _locationService.stopTracking();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppTranslations.t('driver_dashboard'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              'Your shift overview',
              style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.greyText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton.filledTonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DriverProfileScreen(driverId: widget.driverId)),
              );
            },
            icon: const Icon(Icons.person_rounded, size: 22),
            tooltip: 'Profile',
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: IconButton.filledTonal(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 22),
              tooltip: 'Sign out',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.darkText,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stylish "At a glance" card similar to Admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.14),
                    AppTheme.lightGreen.withValues(alpha: 0.09),
                    AppTheme.accentGold.withValues(alpha: 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ACTIVE SHIFT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Driver Status',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your location is currently being shared with the park operations center.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.greyText, height: 1.4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 26),
            Text('Vehicle info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            
            Row(
              children: [
                _statCard(AppTranslations.t('jeep_id'), widget.jeepId, AppTheme.darkText),
                const SizedBox(width: 12),
                _statCard(AppTranslations.t('assigned_block'), widget.block, AppTheme.primaryGreen),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Quick actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            _buildActionItem(
              context: context,
              label: AppTranslations.t('open_live_map'),
              icon: Icons.map_rounded,
              color: AppTheme.primaryGreen,
              onTap: () {
                if (widget.driverId.isEmpty) return;
                Navigator.push(context, MaterialPageRoute(builder: (context) => LiveMapScreen(driverId: widget.driverId)));
              },
            ),
            const SizedBox(height: 12),
            
            _buildActionItem(
              context: context,
              label: AppTranslations.t('report_incident'),
              icon: Icons.report_rounded,
              color: const Color(0xFFC62828),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const IncidentReportScreen()));
              },
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('messages').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                final allMessages = snapshot.data ?? [];
                final unreadCount = allMessages.where((m) {
                  final recipient = m['recipient_driver_id']?.toString();
                  final isRead = m['is_read'] == true;
                  return recipient == widget.driverId && !isRead;
                }).length;

                final label = unreadCount > 0 
                    ? "${AppTranslations.t('View Messages')} ($unreadCount pending)"
                    : AppTranslations.t('View Messages');

                return _buildActionItem(
                  context: context,
                  label: label,
                  icon: Icons.message_rounded,
                  color: unreadCount > 0 ? const Color(0xFFE65100) : AppTheme.darkText,
                  badgeCount: unreadCount,
                  onTap: () {
                    if (widget.driverId.isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MessageScreen(driverId: widget.driverId)));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.greyText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Material(
      color: AppTheme.surface,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              if (badgeCount == 0)
                Icon(Icons.chevron_right_rounded, color: AppTheme.greyText.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
