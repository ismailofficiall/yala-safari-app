import '../widgets/incident_card.dart';

class IncidentFeedScreen extends StatefulWidget {
  final String driverId;
  const IncidentFeedScreen({super.key, required this.driverId});

  @override
  State<IncidentFeedScreen> createState() => _IncidentFeedScreenState();
}

class _IncidentFeedScreenState extends State<IncidentFeedScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Park Incidents'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('incidents')
            .stream(primaryKey: ['id'])
            .eq('is_resolved', false)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final incidents = snapshot.data!;
          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.primaryGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('All clear! No active incidents.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final item = incidents[index];
              final String title = item['title'] ?? 'Incident';
              final String type = item['type'] ?? 'Unknown';
              final String date = _formatDate(item['created_at']);
              final IconData icon = _getIncidentIcon(type);

              return IncidentCard(
                item: item,
                driverId: widget.driverId,
                title: title,
                type: type,
                date: date,
                icon: icon,
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case "wildlife sighting":
      case "wildlife":
        return Icons.pets;
      case "emergency":
        return Icons.warning;
      case "fire":
        return Icons.local_fire_department;
      case "road block":
      case "road_block":
        return Icons.block;
      case "vehicle breakdown":
      case "breakdown":
        return Icons.car_repair;
      default:
        return Icons.report_problem;
    }
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.length >= 16) return s.substring(0, 16).replaceFirst('T', ' ');
    return s;
  }
}
