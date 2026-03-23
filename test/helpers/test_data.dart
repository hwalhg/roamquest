import 'package:roam_quest/data/models/subscription.dart';
import 'package:roam_quest/data/models/checklist_item.dart';
import 'package:roam_quest/data/models/city.dart';

/// Test fixtures for subscription tests
class TestFixtures {
  // Subscription Product IDs
  static const String monthlyProductId = 'com.roamquest.subscription.monthly';
  static const String quarterlyProductId = 'com.roamquest.subscription.quarterly';
  static const String yearlyProductId = 'com.roamquest.subscription.yearly';

  static const String testUserId = 'test_user_123';
  static const String testCityId = '1';

  /// Create a test subscription
  static Subscription createTestSubscription({
    String? id,
    String? userId,
    String productId = monthlyProductId,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
    bool autoRenew = true,
    String? originalTransactionId,
  }) {
    return Subscription(
      id: id ?? 'test_sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: productId,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      isActive: isActive,
      autoRenew: autoRenew,
      originalTransactionId: originalTransactionId ?? 'test_transaction_id',
    );
  }

  /// Create a valid monthly subscription
  static Subscription createValidMonthlySubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_monthly_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: monthlyProductId,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      isActive: true,
      autoRenew: true,
      originalTransactionId: 'test_transaction_monthly',
    );
  }

  /// Create a valid quarterly subscription
  static Subscription createValidQuarterlySubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_quarterly_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: quarterlyProductId,
      startDate: now,
      endDate: now.add(const Duration(days: 90)),
      isActive: true,
      autoRenew: true,
      originalTransactionId: 'test_transaction_quarterly',
    );
  }

  /// Create a valid yearly subscription
  static Subscription createValidYearlySubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_yearly_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: yearlyProductId,
      startDate: now,
      endDate: now.add(const Duration(days: 365)),
      isActive: true,
      autoRenew: true,
      originalTransactionId: 'test_transaction_yearly',
    );
  }

  /// Create an expired subscription
  static Subscription createExpiredSubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_expired_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: monthlyProductId,
      startDate: now.subtract(const Duration(days: 60)),
      endDate: now.subtract(const Duration(days: 1)),
      isActive: true,
      autoRenew: false,
      originalTransactionId: 'test_transaction_expired',
    );
  }

  /// Create a subscription expiring soon (within 3 days)
  static Subscription createExpiringSoonSubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_expiring_soon_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: monthlyProductId,
      startDate: now.subtract(const Duration(days: 27)),
      endDate: now.add(const Duration(days: 2)),
      isActive: true,
      autoRenew: true,
      originalTransactionId: 'test_transaction_expiring_soon',
    );
  }

  /// Create an inactive subscription
  static Subscription createInactiveSubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_inactive_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: monthlyProductId,
      startDate: now.subtract(const Duration(days: 10)),
      endDate: now.add(const Duration(days: 20)),
      isActive: false,
      autoRenew: false,
      originalTransactionId: 'test_transaction_inactive',
    );
  }

  /// Create a lifetime subscription (no end date)
  static Subscription createLifetimeSubscription({
    String? userId,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub_lifetime_${now.millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      productId: yearlyProductId,
      startDate: now,
      endDate: null,
      isActive: true,
      autoRenew: false,
      originalTransactionId: 'test_transaction_lifetime',
    );
  }

  /// Create test checklist items
  static List<ChecklistItem> createTestItems({
    int landmarkCount = 5,
    int foodCount = 5,
    int experienceCount = 5,
    int hiddenCount = 5,
    bool completed = false,
    String? cityId,
  }) {
    final items = <ChecklistItem>[];
    final itemId = DateTime.now().millisecondsSinceEpoch;

    // Create landmark items
    for (int i = 0; i < landmarkCount; i++) {
      items.add(ChecklistItem(
        id: 'test_landmark_${itemId}_$i',
        checklistId: 'test_checklist_${cityId ?? 1}',
        attractionId: i,
        title: 'Test Landmark $i',
        location: 'Test Location $i',
        category: 'landmark',
        sortOrder: i,
        isCompleted: completed,
        photoUrl: completed ? 'https://example.com/photo$i.jpg' : null,
        completedAt: completed ? DateTime.now() : null,
        rating: completed ? 8 : null,
      ));
    }

    // Create food items
    for (int i = 0; i < foodCount; i++) {
      items.add(ChecklistItem(
        id: 'test_food_${itemId}_$i',
        checklistId: 'test_checklist_${cityId ?? 1}',
        attractionId: landmarkCount + i,
        title: 'Test Food $i',
        location: 'Test Food Location $i',
        category: 'food',
        sortOrder: landmarkCount + i,
        isCompleted: completed,
        photoUrl: completed ? 'https://example.com/food$i.jpg' : null,
        completedAt: completed ? DateTime.now() : null,
        rating: completed ? 7 : null,
      ));
    }

    // Create experience items
    for (int i = 0; i < experienceCount; i++) {
      items.add(ChecklistItem(
        id: 'test_experience_${itemId}_$i',
        checklistId: 'test_checklist_${cityId ?? 1}',
        attractionId: landmarkCount + foodCount + i,
        title: 'Test Experience $i',
        location: 'Test Experience Location $i',
        category: 'experience',
        sortOrder: landmarkCount + foodCount + i,
        isCompleted: completed,
        photoUrl: completed ? 'https://example.com/exp$i.jpg' : null,
        completedAt: completed ? DateTime.now() : null,
        rating: completed ? 9 : null,
      ));
    }

    // Create hidden gem items
    for (int i = 0; i < hiddenCount; i++) {
      items.add(ChecklistItem(
        id: 'test_hidden_${itemId}_$i',
        checklistId: 'test_checklist_${cityId ?? 1}',
        attractionId: landmarkCount + foodCount + experienceCount + i,
        title: 'Test Hidden Gem $i',
        location: 'Test Hidden Location $i',
        category: 'hidden',
        sortOrder: landmarkCount + foodCount + experienceCount + i,
        isCompleted: completed,
        photoUrl: completed ? 'https://example.com/hidden$i.jpg' : null,
        completedAt: completed ? DateTime.now() : null,
        rating: completed ? 8 : null,
      ));
    }

    return items;
  }

  /// Create a test city
  static City createTestCity({
    int? id,
    String name = 'San Francisco',
    String country = 'United States',
    String countryCode = 'US',
  }) {
    return City(
      id: id ?? 1,
      name: name,
      country: country,
      countryCode: countryCode,
      latitude: 37.7749,
      longitude: -122.4194,
      isActive: true,
    );
  }

  /// Get completed items from test items
  static List<ChecklistItem> getCompletedItems(List<ChecklistItem> items) {
    return items.where((item) => item.isCompleted).toList();
  }

  /// Get items by category
  static List<ChecklistItem> getItemsByCategory(
    List<ChecklistItem> items,
    String category,
  ) {
    return items.where((item) => item.category == category).toList();
  }

  /// Get completed count by category
  static Map<String, int> getCompletedCountByCategory(List<ChecklistItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      if (item.isCompleted) {
        counts[item.category] = (counts[item.category] ?? 0) + 1;
      } else {
        counts[item.category] = counts[item.category] ?? 0;
      }
    }
    return counts;
  }
}
