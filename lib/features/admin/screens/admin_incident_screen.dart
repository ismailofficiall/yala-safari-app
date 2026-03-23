import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../widgets/admin_app_bar_actions.dart';

class AdminIncidentScreen extends StatefulWidget {
  const AdminIncidentScreen({super.key});

  @override
  State<AdminIncidentScreen> createState() => _AdminIncidentScreenState();
}

class _AdminIncidentScreenState extends State<AdminIncidentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsResolved(String id) async {
    try {
      await _supabase.from('incidents').update({'is_resolved': true}).eq('id', id);
      
      await _supabase.from('audit_logs').insert({
        'action': 'Incident Resolved',
        'entity': 'Incident ID: $id',
        'performed_by': 'Admin',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident marked resolved'), backgroundColor: AdminTheme.primaryGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showIncidentSheet(Map<String, dynamic> item, {required bool isResolved}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AdminTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22, right: 22, top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${item['title'] ?? 'Incident'}',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${item['latitude'] ?? '?'} Lng: ${item['longitude'] ?? '?'} · ${_formatDate(item['created_at'])}',
                style: const TextStyle(color: AdminTheme.greyText, fontWeight: FontWeight.w500),
              ),
              if (item['note'] != null && '${item['note']}'.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Driver Notes:\n${item['note']}', style: const TextStyle(height: 1.4)),
              ],
              if (item['image_url'] != null && '${item['image_url']}'.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    '${item['image_url']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Text('Could not load image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              if (!isResolved) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _markAsResolved('${item['id']}');
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark resolved'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Incidents', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              'Reported issues · live list',
              style: theme.textTheme.labelMedium?.copyWith(color: AdminTheme.greyText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: const [AdminAppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AdminTheme.primaryGreen,
          unselectedLabelColor: AdminTheme.greyText,
          indicatorColor: AdminTheme.primaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber_rounded), text: "Active"),
            Tab(icon: Icon(Icons.check_circle_outline), text: "Resolved"),
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
          TabBarView(
            controller: _tabController,
            children: [
              _buildList(isResolved: false),
              _buildList(isResolved: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList({required bool isResolved}) {
    final stream = _supabase
        .from('incidents')
        .stream(primaryKey: ['id'])
        .eq('is_resolved', isResolved)
        .order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final incidents = snapshot.data!;
        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isResolved ? Icons.check_circle_outline : Icons.sentiment_satisfied_alt_outlined,
                  size: 56,
                  color: AdminTheme.primaryGreen.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 16),
                Text(
                  isResolved ? 'No resolved incidents yet' : 'All clear — no open incidents',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final item = incidents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AdminTheme.surface,
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  onTap: () => _showIncidentSheet(item, isResolved: isResolved),
                  leading: CircleAvatar(
                    backgroundColor: isResolved
                        ? AdminTheme.lightGreen.withValues(alpha: 0.22)
                        : Colors.red.withValues(alpha: 0.12),
                    child: Icon(
                      isResolved ? Icons.check_rounded : Icons.priority_high_rounded,
                      color: isResolved ? AdminTheme.primaryGreen : const Color(0xFFC62828),
                    ),
                  ),
                  title: Text('${item['title']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${item['type'] ?? 'Unknown'} · ${_formatDate(item['created_at'])}',
                      style: const TextStyle(color: AdminTheme.greyText, fontSize: 13),
                    ),
                  ),
                  trailing: !isResolved
                      ? FilledButton.tonal(
                          onPressed: () => _markAsResolved('${item['id']}'),
                          child: const Text('Resolve'),
                        )
                      : Icon(Icons.verified_rounded, color: AdminTheme.greyText.withValues(alpha: 0.7)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _formatDate(dynamic v) {
  if (v == null) return '—';
  final s = v.toString();
  if (s.length >= 10) return s.substring(0, 10);
  return s;
}
