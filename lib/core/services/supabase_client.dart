/// Supabase Configuration & Backend Services
/// Handles initialization and connection keys.

library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase connection keys

  static const String supabaseUrl = "https://entzwknecnwcbspqcbuk.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVudHp3a25lY253Y2JzcHFjYnVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1MTA5MDUsImV4cCI6MjA4OTA4NjkwNX0.96EH2JKnFsT5XfxNFMX-RfbJByOKSy-yT0sCEZsBP6g";

  /// Initializes the Supabase instance.
  /// Must be called once during app startup (e.g., inside `main()`).
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  /// A static and global getter for the Supabase client.
  /// This prevents us from having to call `Supabase.instance.client` 
  /// manually inside every single widget or service file.
  static SupabaseClient get client => Supabase.instance.client;
}
