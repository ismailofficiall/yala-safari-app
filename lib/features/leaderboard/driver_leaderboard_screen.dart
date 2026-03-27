import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';

/// Displays an ordered leaderboard of all active drivers ranked by performance rating.
/// Pulls live data from the `drivers` table in Supabase.
/// Both drivers and admins can view this screen for motivation and benchmarking.
class DriverLeaderboardScreen extends StatelessWidget {
  const DriverLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Driver Leaderboard", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Fetch all drivers ordered from highest to lowest rating
        stream: Supabase.instance.client
            .from('drivers')
            .stream(primaryKey: ['id'])
            .order('rating', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final drivers = snapshot.data!;
          if (drivers.isEmpty) return const Center(child: Text("No drivers found."));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              final double rating = (d['rating'] is num) ? (d['rating'] as num).toDouble() : 5.0;
              final String name = d['driver_name'] ?? 'Unknown';
              final String jeepId = d['jeep_id'] ?? 'N/A';
              final String status = d['status'] ?? 'Active';

              // Medal assignment for top 3 positions
              final medals = ['🥇', '🥈', '🥉'];
              final rankLabel = index < 3 ? medals[index] : '#${index + 1}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppTheme.accentGold.withValues(alpha: 0.08)  // Gold tint for #1
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: index == 0
                          ? AppTheme.accentGold.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Rank label on the left
                    leading: SizedBox(
                      width: 44,
                      child: Center(
                        child: Text(
                          rankLabel,
                          style: TextStyle(fontSize: index < 3 ? 28 : 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    subtitle: Text("Jeep: $jeepId · $status", style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Star icon + numeric rating on the right
                        const Icon(Icons.star_rounded, color: AppTheme.accentGold, size: 20),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
