import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../widgets/admin_app_bar_actions.dart';

/// Admin Audit Log screen: displays a chronological timeline of key platform
/// events (driver status changes, new driver registrations, incident resolutions).
/// Records are stored in the `audit_logs` table in Supabase.
class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

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
            Text('Audit Log', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('System activity timeline', style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.12,
            child: SizedBox.expand(
              child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            // Stream audit_logs ordered from newest to oldest
        stream: Supabase.instance.client
            .from('audit_logs')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AdminTheme.primaryGreen.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text("No audit events yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text("Actions will appear here once they occur", style: TextStyle(color: AdminTheme.greyText)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final action = log['action']?.toString() ?? 'Unknown Action';
              final entity = log['entity']?.toString() ?? '';
              final admin = log['performed_by']?.toString() ?? 'System';
              final createdAt = log['created_at']?.toString().substring(0, 16) ?? '';

              IconData icon;
              Color color;

              // Assign icons and colors based on action type string
              if (action.contains('Suspended')) {
                icon = Icons.block_rounded;
                color = Colors.red;
              } else if (action.contains('Activated') || action.contains('Reactivated')) {
                icon = Icons.check_circle_rounded;
                color = AdminTheme.primaryGreen;
              } else if (action.contains('Added')) {
                icon = Icons.person_add_rounded;
                color = Colors.blue;
              } else if (action.contains('Resolved')) {
                icon = Icons.verified_rounded;
                color = AdminTheme.primaryGreen;
              } else {
                icon = Icons.info_rounded;
                color = AdminTheme.greyText;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(action, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entity.isNotEmpty) Text('Target: $entity', style: const TextStyle(color: AdminTheme.greyText, fontSize: 12)),
                        Text('By: $admin · $createdAt', style: const TextStyle(color: AdminTheme.greyText, fontSize: 12)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ); // closes ListView.builder
        }, // closes StreamBuilder's builder function
      ), // closes StreamBuilder
      ], // closes Stack children
      ), // closes Stack
    ); // closes Scaffold
  }
}
