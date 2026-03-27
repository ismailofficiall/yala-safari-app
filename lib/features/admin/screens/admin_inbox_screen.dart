import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import 'admin_chat_screen.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  final _client = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Conversations')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _client.from('messages').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Group messages by driver
          final allMessages = snapshot.data ?? [];
          final Map<String, Map<String, dynamic>> latestMessages = {};
          final Map<String, int> unreadCounts = {};

          for (final m in allMessages.reversed) {
            String driverId = '';
            
            if (m['recipient_driver_id'] == 'HQ' && m['sender_name'] != null) {
              driverId = m['sender_name'].toString().replaceAll('Driver ID: ', '');
            } else if (m['sender_name'] == 'HQ') {
              driverId = m['recipient_driver_id'].toString();
            }

            if (driverId.isEmpty) continue;

            latestMessages[driverId] = m;
            
            // Count unread messages sent TO HQ from this driver
            if (m['recipient_driver_id'] == 'HQ' && m['is_read'] == false) {
              unreadCounts[driverId] = (unreadCounts[driverId] ?? 0) + 1;
            }
          }

          if (latestMessages.isEmpty) {
            return const Center(child: Text('Inbox is clean. No driver messages.'));
          }

          final threadedDrivers = latestMessages.keys.toList()
            ..sort((a, b) {
              // Sort by who has unread messages first, then chronologically
              final unreadA = unreadCounts[a] ?? 0;
              final unreadB = unreadCounts[b] ?? 0;
              if (unreadA > 0 && unreadB == 0) return -1;
              if (unreadB > 0 && unreadA == 0) return 1;
              
              final timeA = DateTime.tryParse(latestMessages[a]!['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final timeB = DateTime.tryParse(latestMessages[b]!['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              return timeB.compareTo(timeA);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threadedDrivers.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final driverId = threadedDrivers[index];
              final latestMsg = latestMessages[driverId]!;
              final unread = unreadCounts[driverId] ?? 0;
              
              return ListTile(
                tileColor: unread > 0 ? AdminTheme.primaryGreen.withValues(alpha: 0.05) : AdminTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
                leading: CircleAvatar(
                  backgroundColor: unread > 0 ? Colors.red : AdminTheme.primaryGreen,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text('Driver $driverId', style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(
                  '${latestMsg['body']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: unread > 0 ? Colors.black87 : Colors.black54),
                ),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    : const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminChatScreen(driverId: driverId)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
