import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';

class MessageScreen extends StatefulWidget {
  final String driverId;
  const MessageScreen({super.key, required this.driverId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _client = Supabase.instance.client;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _client.from('messages').insert({
        'recipient_driver_id': 'HQ',
        'subject': 'Chat',
        'body': text,
        'sender_name': 'Driver ID: ${widget.driverId}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _msgCtrl.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _client.from('messages').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with HQ', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _client.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final msgs = (snapshot.data ?? []).where((m) {
                  // Show messages where driver is recipient or driver is sender (to HQ)
                  final isToDriver = m['recipient_driver_id']?.toString() == widget.driverId;
                  final isFromDriver = m['sender_name']?.toString() == 'Driver ID: ${widget.driverId}';
                  return isToDriver || isFromDriver;
                }).toList();

                if (msgs.isEmpty) {
                  return const Center(child: Text("No chat history. Send a message to HQ."));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // StreamBuilder will handle the refresh automatically,
                    // but we can add a small delay to show the indicator.
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final m = msgs[index];
                      final isFromDriver = m['sender_name']?.toString() == 'Driver ID: ${widget.driverId}';
                      
                      // Mark Admin messages as read if driver sees them
                      if (!isFromDriver && m['is_read'] != true && m['id'] != null) {
                        _markAsRead(m['id'].toString());
                      }

                      final timeFormat = DateFormat('MMM dd, HH:mm').format(
                        DateTime.tryParse(m['created_at'].toString())?.toLocal() ?? DateTime.now()
                      );

                      return Align(
                        alignment: isFromDriver ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isFromDriver ? AppTheme.primaryGreen : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isFromDriver ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isFromDriver ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isFromDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['body']?.toString() ?? '',
                                style: TextStyle(color: isFromDriver ? Colors.white : Colors.black87, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeFormat,
                                style: TextStyle(color: isFromDriver ? Colors.white70 : Colors.black54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Chat Input Area
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryGreen,
                  child: IconButton(
                    icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
