/// Supabase Configuration & Backend Services
/// Handles initialization and connection keys.

library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase connection keys

  static const String supabaseUrl = "https://entzwknecnwcbspqcbuk.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVudHp3a25lY253Y2JzcHFjYnVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1MTA5MDUsImV4cCI6MjA4OTA4NjkwNX0.96EH2JKnFsT5XfxNFMX-RfbJByOKSy-yT0sCEZsBP6g";

  /// Initializes the Supabase instance using fixed developer credentials.
  /// 
  /// This must be called exactly once during the application's initialization
  /// sequence (typically located within `main()`). Ensure all environment
  /// dependencies are correctly configured beforehand.
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  /// Provides a static access point to the globally shared Supabase client.
  /// 
  /// Using this getter ensures that we avoid repetitive `Supabase.instance.client`
  /// chains throughout the application features, facilitating easier unit testing 
  /// and mock injection down the line.
  static SupabaseClient get client => Supabase.instance.client;
}
