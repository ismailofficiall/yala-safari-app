import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminAccess { allowed, denied, misconfigured }

class AdminService {
  AdminService._();

  static final _client = Supabase.instance.client;

  static Future<AdminAccess> checkAdminAccess() async {
    final user = _client.auth.currentUser;
    if (user == null) return AdminAccess.denied;

    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) return AdminAccess.denied;

      final role = row['role'] as String?;
      if (role == 'admin') return AdminAccess.allowed;
      return AdminAccess.denied;
    } on PostgrestException catch (e) {
      final code = e.code;
      if (code == 'PGRST116' || code == '42P01') {
        return AdminAccess.misconfigured;
      }
      return AdminAccess.misconfigured;
    } catch (_) {
      return AdminAccess.misconfigured;
    }
  }
}
