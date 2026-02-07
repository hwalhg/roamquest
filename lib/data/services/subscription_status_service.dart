import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/city.dart';
import '../models/checklist_item.dart';
import 'auth_service.dart';

/// Service for managing per-city subscription status
class SubscriptionStatusService {
  final SupabaseClient _client = SupabaseConfig.client;
  final AuthService _authService = AuthService();

  /// Check if a city is unlocked for the current user
  Future<bool> isCityUnlocked(City city) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    // Free cities are always unlocked
    if (city.isFree) return true;

    try {
      final response = await _client
          .from('user_cities')
          .select()
          .eq('user_id', userId)
          .eq('city_name', city.name)
          .eq('country', city.country)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Unlock a city for the current user
  Future<bool> unlockCity(City city) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client.from('user_cities').insert({
        'user_id': userId,
        'city_name': city.name,
        'country': city.country,
      });

      return true;
    } catch (e) {
      print('Error unlocking city: $e');
      return false;
    }
  }

  /// Get list of unlocked cities for the current user
  Future<List<String>> getUnlockedCityNames() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('user_cities')
          .select('city_name')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => row['city_name'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if user can check in to an item (free tier limitation)
  /// Returns true if:
  /// - City is unlocked, OR
  /// - Not yet reached free tier limits (1 per category: landmark, food, experience)
  Future<bool> canCheckIn(
    City city,
    List<ChecklistItem> completedItems,
    ChecklistItem? itemToCheck,
  ) async {
    // If city is unlocked, no restrictions
    if (await isCityUnlocked(city)) return true;

    // Count by category for remaining free tier
    final landmarkCount = completedItems
        .where((item) => item.category == 'landmark' && item.isCompleted)
        .length;

    final foodCount = completedItems
        .where((item) => item.category == 'food' && item.isCompleted)
        .length;

    final experienceCount = completedItems
        .where((item) => item.category == 'experience' && item.isCompleted)
        .length;

    // Free tier limits: 1 per category
    if (landmarkCount >= 1) return false;
    if (foodCount >= 1) return false;
    if (experienceCount >= 1) return false;

    return true;
  }

  /// Get remaining free check-ins for each category
  Future<Map<String, int>> getRemainingFreeCheckIns(
    City city,
    List<ChecklistItem> completedItems,
  ) async {
    if (await isCityUnlocked(city)) {
      return {'landmark': 999, 'food': 999, 'experience': 999};
    }

    final landmarkCount = completedItems
        .where((item) => item.category == 'landmark' && item.isCompleted)
        .length;

    final foodCount = completedItems
        .where((item) => item.category == 'food' && item.isCompleted)
        .length;

    final experienceCount = completedItems
        .where((item) => item.category == 'experience' && item.isCompleted)
        .length;

    return {
      'landmark': 1 - landmarkCount,
      'food': 1 - foodCount,
      'experience': 1 - experienceCount,
    };
  }
}
