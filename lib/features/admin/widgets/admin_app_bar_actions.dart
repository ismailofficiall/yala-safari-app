import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../screens/admin_inbox_screen.dart';

class AdminAppBarActions extends StatelessWidget {
  const AdminAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client.from('messages').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            final unreadCount = (snapshot.data ?? []).where((m) => m['recipient_driver_id'] == 'HQ' && m['is_read'] == false).length;
            return Stack(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInboxScreen())),
                  icon: const Icon(Icons.mark_email_unread_rounded, size: 22),
                  tooltip: 'Inbox',
                  style: IconButton.styleFrom(
                    foregroundColor: AdminTheme.darkText,
                    backgroundColor: AdminTheme.primaryGreen.withOpacity(0.12),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4, top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton.filledTonal(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Sign out',
            style: IconButton.styleFrom(
              foregroundColor: AdminTheme.darkText,
              backgroundColor: AdminTheme.primaryGreen.withOpacity(0.12),
            ),
          ),
        ),
      ],
    );
  }
}
