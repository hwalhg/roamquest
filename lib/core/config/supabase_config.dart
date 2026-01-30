import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_constants.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static bool _isInitialized = false;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      debug: true,
    );

    _isInitialized = true;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Get current auth state
  static bool get isAuthenticated => client.auth.currentSession != null;

  /// Get current user
  static String? get currentUserId => client.auth.currentUser?.id;
}
