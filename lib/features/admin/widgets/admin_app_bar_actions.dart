import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';

class AdminAppBarActions extends StatelessWidget {
  const AdminAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
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
          backgroundColor: AdminTheme.primaryGreen.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
