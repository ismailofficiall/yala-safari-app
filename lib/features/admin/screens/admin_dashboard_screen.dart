import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../widgets/admin_app_bar_actions.dart';
import 'add_driver_screen.dart';
import 'driver_details.dart';
import 'admin_incident_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dashboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              'Live overview',
              style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: const [AdminAppBarActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDriverScreen()));
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New driver'),
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AdminTheme.primaryGreen.withValues(alpha: 0.14),
                    AdminTheme.lightGreen.withValues(alpha: 0.09),
                    AdminTheme.accentGold.withValues(alpha: 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AdminTheme.primaryGreen.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: AdminTheme.primaryGreen.withValues(alpha: 0.12),
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
                      color: AdminTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'YALA NATIONAL PARK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AdminTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Operations',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.darkText,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fleet health & incidents update live from Supabase.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AdminTheme.greyText, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text('At a glance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildCountCard(
                    supabase.from('drivers').stream(primaryKey: ['id']).eq('status', 'Active'),
                    'Active jeeps',
                    Icons.directions_car_filled_rounded,
                    AdminTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCountCard(
                    supabase.from('incidents').stream(primaryKey: ['id']).eq('is_resolved', false),
                    'Open alerts',
                    Icons.notifications_active_rounded,
                    const Color(0xFFE65100),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminIncidentScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Drivers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('By rating', style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Tap a row for full profile & actions', style: theme.textTheme.bodySmall?.copyWith(color: AdminTheme.greyText)),
            const SizedBox(height: 14),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('drivers').stream(primaryKey: ['id']).order('rating', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Msg(icon: Icons.cloud_off_outlined, title: 'Could not load drivers', detail: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                }

                final drivers = snapshot.data!;
                if (drivers.isEmpty) {
                  return const _Msg(icon: Icons.groups_outlined, title: 'No drivers yet', detail: 'Use New driver to register someone.');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: drivers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = drivers[index];
                    final rating = (d['rating'] is num) ? (d['rating'] as num).toDouble() : 5.0;
                    final bool isLowRating = rating < 3.5;
                    final ratingLabel = (rating % 1 == 0) ? rating.toInt().toString() : rating.toStringAsFixed(1);
                    final active = d['status'] == 'Active';

                    return Material(
                      color: AdminTheme.surface,
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: isLowRating
                              ? Colors.red.withValues(alpha: 0.12)
                              : AdminTheme.lightGreen.withValues(alpha: 0.2),
                          child: Text(
                            ratingLabel,
                            style: TextStyle(
                              color: isLowRating ? const Color(0xFFC62828) : AdminTheme.primaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text('${d['driver_name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('ID ${d['driver_id_code']}', style: TextStyle(color: AdminTheme.greyText, fontSize: 13)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                : const Color(0xFFEF6C00).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${d['status']}',
                            style: TextStyle(
                              color: active ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DriverDetails(driver: d))),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(Stream<List<Map<String, dynamic>>> stream, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AdminTheme.surface, color.withValues(alpha: 0.07)],
                ),
                border: Border.all(color: color.withValues(alpha: 0.22)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.8)),
                    const SizedBox(height: 4),
                    Text(label, textAlign: TextAlign.center, style: TextStyle(color: AdminTheme.greyText, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Msg extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _Msg({required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: AdminTheme.primaryGreen.withValues(alpha: 0.85)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(detail, style: const TextStyle(color: AdminTheme.greyText, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
