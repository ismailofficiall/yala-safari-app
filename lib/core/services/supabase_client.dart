/// =========================================================================
/// Supabase Configuration & Backend Services
/// =========================================================================
/// This file encapsulates the configuration for Supabase, our open-source
/// Firebase alternative used for PostgreSQL database management, realtime
/// subscriptions, and authentication.
///
/// Coursework Note: 
/// Organizing backend keys and connection logic into a dedicated Singleton-
/// like service keeps the architecture modular. If the project ever routes
/// to a different backend (e.g., Firebase Firestore, custom REST API), only 
/// this specific file and its direct delegates need to change.
/// =========================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Coursework Note: In a production environment, these sensitive keys
  // should ideally be stored in a `.env` file (e.g., using flutter_dotenv) 
  // to avoid exposing secrets in version control systems like GitHub.
  static const String supabaseUrl = "https://entzwknecnwcbspqcbuk.supabase.co/";
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
