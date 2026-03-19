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

  /// Check if a city is unlocked for current user
  /// 用户已有该城市的 checklist 就表示已解锁
  Future<bool> isCityUnlocked(City city) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    // Free cities are always unlocked
    if (city.isFree) return true;

    try {
      // 检查用户是否已有该城市的 checklist
      final response = await _client
          .from('checklists')
          .select()
          .eq('user_id', userId)
          .eq('city_id', city.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('Error checking city unlock status', error: e);
      return false;
    }
  }

  /// Unlock a city for current user
  /// 创建 checklist 时即自动解锁，无需单独操作
  Future<bool> unlockCity(City city) async {
    // 创建 checklist 时已经自动"解锁"城市了
    // 不需要单独的解锁操作
    return true;
  }

  /// Get list of unlocked cities for current user
  /// 从用户的 checklists 中获取所有已解锁的城市
  Future<List<String>> getUnlockedCityNames() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('checklists')
          .select('city_id')
          .eq('user_id', userId);

      // 需要关联 cities 表获取城市名
      final cityIds = (response as List)
          .map((row) => row['city_id'] as int)
          .toSet();

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
      AppLogger.error('Error getting unlocked cities', error: e);
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
