import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';
import '../models/city.dart';
import '../models/checklist_item.dart';
import 'auth_service.dart';

/// Service for managing per-city subscription status
class SubscriptionStatusService {
  final SupabaseClient _client = SupabaseConfig.client;
  final AuthService _authService = AuthService();

  /// Check if user has a currently active premium subscription.
  Future<bool> hasPremiumSubscription() async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('end_date', DateTime.now().toIso8601String())
          .maybeSingle();

      final hasActiveSubscription = response != null;
      AppLogger.info(
          'Premium subscription check: $hasActiveSubscription for user $userId');
      return hasActiveSubscription;
    } catch (e) {
      AppLogger.error('Error checking premium subscription from database',
          error: e);
      return false;
    }
  }

  /// Check if the user has already started this city by creating a checklist.
  Future<bool> hasStartedCity(City city) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('checklists')
          .select()
          .eq('user_id', userId)
          .eq('city_id', city.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('Error checking city checklist', error: e);
      return false;
    }
  }

  /// Backward-compatible alias for started-city checks.
  Future<bool> hasChecklistForCity(City city) async {
    return hasStartedCity(city);
  }

  /// Check whether the user can access this city right now.
  /// Premium means all cities are accessible, even if the user has not started them yet.
  Future<bool> hasAccessToCity(City city) async {
    if (city.isFree) return true;

    if (await hasPremiumSubscription()) {
      return true;
    }

    return hasStartedCity(city);
  }

  /// Get the list of cities the user has actually started.
  Future<List<String>> getStartedCityNames() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('checklists')
          .select('city_id')
          .eq('user_id', userId);

      // 需要关联 cities 表获取城市名
      final cityIds =
          (response as List).map((row) => row['city_id'] as int).toSet();

      if (cityIds.isEmpty) return [];

      // 从 cities 表获取城市名
      final citiesResponse = await _client
          .from('cities')
          .select('name')
          .inFilter('id', cityIds.toList());

      return (citiesResponse as List)
          .map((city) => city['name'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting started cities', error: e);
      return [];
    }
  }

  /// Backward-compatible alias for existing callers that expect checklist history.
  Future<List<String>> getUnlockedCityNames() async {
    return getStartedCityNames();
  }

  /// Check if user can check in to an item
  /// Returns true if:
  /// - The item is free (isFree = true), OR
  /// - The city itself is free, OR
  /// - User currently has an active premium subscription
  Future<bool> canCheckIn(
    City city,
    List<ChecklistItem> completedItems,
    ChecklistItem? itemToCheck,
  ) async {
    if (itemToCheck != null && itemToCheck.isCustom) {
      AppLogger.info('Custom item detected: ${itemToCheck.title}');
      return true;
    }

    // Free items: always allowed
    if (itemToCheck != null && itemToCheck.isFree) {
      AppLogger.info('Free item detected: ${itemToCheck.title}');
      return true;
    }

    if (city.isFree) {
      AppLogger.info('Free city detected, allowing check-in');
      return true;
    }

    if (await hasPremiumSubscription()) {
      AppLogger.info('Premium subscription active, allowing check-in');
      return true;
    }

    AppLogger.info('Item is locked and requires subscription');
    return false;
  }

  /// Get remaining free check-ins for each category
  Future<Map<String, int>> getRemainingFreeCheckIns(
    City city,
    List<ChecklistItem> completedItems,
  ) async {
    if (await hasPremiumSubscription()) {
      return {'landmark': 999, 'food': 999, 'experience': 999, 'hidden': 999};
    }

    // Free tier: count remaining
    final landmarkCount = completedItems
        .where((item) =>
            item.category == 'landmark' &&
            item.isCompleted &&
            !item.isCustom)
        .length;

    final foodCount = completedItems
        .where((item) =>
            item.category == 'food' && item.isCompleted && !item.isCustom)
        .length;

    final experienceCount = completedItems
        .where((item) =>
            item.category == 'experience' &&
            item.isCompleted &&
            !item.isCustom)
        .length;

    final hiddenCount = completedItems
        .where((item) =>
            item.category == 'hidden' && item.isCompleted && !item.isCustom)
        .length;

    return {
      'landmark': 1 - landmarkCount,
      'food': 1 - foodCount,
      'experience': 1 - experienceCount,
      'hidden': 1 - hiddenCount,
    };
  }
}
