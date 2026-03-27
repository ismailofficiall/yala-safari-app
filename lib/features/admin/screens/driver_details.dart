import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import 'admin_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDetails extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverDetails({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(driver['driver_name'] ?? 'Driver'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('drivers').stream(primaryKey: ['id']).eq('id', driver['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load driver: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final d = snapshot.data!.first;
          final rating = (d['rating'] is num) ? (d['rating'] as num).toDouble() : 5.0;
          final bool isLowRating = rating < 3.5;
          final bool isActive = d['status'] == 'Active';
          final ratingLabel = (rating % 1 == 0) ? rating.toInt().toString() : rating.toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AdminTheme.primaryGreen.withValues(alpha: 0.5),
                        AdminTheme.accentGold.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: AdminTheme.surface,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: isLowRating
                          ? Colors.red.withValues(alpha: 0.12)
                          : AdminTheme.lightGreen.withValues(alpha: 0.22),
                      backgroundImage: d['image_url'] != null ? NetworkImage(d['image_url']) : null,
                      child: d['image_url'] == null ? Text(
                        ratingLabel,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isLowRating ? const Color(0xFFC62828) : AdminTheme.primaryGreen,
                        ),
                      ) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  d['image_url'] != null ? 'Rating: $ratingLabel' : 'Rating',
                  style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID ${d['driver_id_code']}',
                  style: theme.textTheme.titleMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w600),
                ),
                if (d['phone_number'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${d['phone_number']}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AdminTheme.primaryGreen, fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    _statCard('Status', '${d['status']}', isActive ? AdminTheme.primaryGreen : const Color(0xFFEF6C00)),
                    const SizedBox(width: 12),
                    _statCard('Jeep', '${d['jeep_id'] ?? '—'}', AdminTheme.darkText),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(driverId: d['id'].toString()))),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (d['phone_number'] != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final url = Uri.parse('tel:${d['phone_number']}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.phone_enabled_rounded),
                          label: const Text('Call'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminTheme.primaryGreen.withValues(alpha: 0.1),
                            foregroundColor: AdminTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFFB71C1C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      try {
                        await supabase.from('drivers').update({
                          'status': isActive ? 'Suspended' : 'Active',
                        }).eq('id', d['id']);

                        // Insert a record into the audit log for the dashboard timeline
                        await supabase.from('audit_logs').insert({
                          'action': isActive ? 'Driver Suspended' : 'Driver Reactivated',
                          'entity': d['driver_name'] ?? 'Unknown Driver',
                          'performed_by': 'Admin',
                          'created_at': DateTime.now().toIso8601String(),
                        });

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isActive ? 'Driver suspended' : 'Driver reactivated'),
                            backgroundColor: AdminTheme.primaryGreen,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                    label: Text(isActive ? 'Suspend driver' : 'Reactivate driver'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AdminTheme.greyText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

}
