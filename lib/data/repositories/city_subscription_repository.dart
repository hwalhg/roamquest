import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';

/// Repository for managing city unlock status (checking only, no purchasing)
/// Purchasing is now handled by SubscriptionRepository (global subscription)
class CitySubscriptionRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Check if a specific city is unlocked
  Future<bool> isCityUnlocked(String cityName) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
      final result = await _client
          .from('user_cities')
          .select()
          .eq('user_id', userId)
          .eq('city_name', cityName)
          .maybeSingle();

      return result != null;
    } catch (e) {
      AppLogger.error('Failed to check city unlock status', error: e);
      return false;
    }
  }

  /// Unlock city in database
  Future<void> unlockCityInDatabase(String cityName) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.error('User not authenticated');
      return;
    }

    try {
      // Check if already unlocked
      final existing = await _client
          .from('user_cities')
          .select()
          .eq('user_id', userId)
          .eq('city_name', cityName)
          .maybeSingle();

      if (existing == null) {
        // Add unlock record
        await _client.from('user_cities').insert({
          'user_id': userId,
          'city_name': cityName,
          'unlocked_at': DateTime.now().toIso8601String(),
          'is_permanent': true,
        });
        AppLogger.info('Unlocked city in database: $cityName');
      }
    } catch (e) {
      AppLogger.error('Failed to unlock city in database', error: e);
    }
  }
}
