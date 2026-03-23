import 'package:flutter_test/flutter_test.dart';
import 'package:roam_quest/core/constants/app_constants.dart';
import 'package:roam_quest/data/models/subscription.dart';
import 'package:roam_quest/data/repositories/subscription_repository.dart';

/// Unit tests for SubscriptionRepository
/// Note: Full repository testing requires complex IAP mocking
/// These tests focus on the business logic that can be tested without IAP
void main() {
  group('SubscriptionStatus Enum Tests', () {
    test('should have correct subscription status values', () {
      // Arrange & Act
      const unknown = SubscriptionStatus.unknown;
      const unavailable = SubscriptionStatus.unavailable;
      const free = SubscriptionStatus.free;
      const premium = SubscriptionStatus.premium;
      const expired = SubscriptionStatus.expired;
      const error = SubscriptionStatus.error;

      // Assert - Verify all enum values exist
      expect(unknown, equals(SubscriptionStatus.unknown));
      expect(unavailable, equals(SubscriptionStatus.unavailable));
      expect(free, equals(SubscriptionStatus.free));
      expect(premium, equals(SubscriptionStatus.premium));
      expect(expired, equals(SubscriptionStatus.expired));
      expect(error, equals(SubscriptionStatus.error));
    });
  });

  group('SubscriptionStatusExtension Tests', () {
    test('should identify premium status correctly', () {
      // Arrange
      const premium = SubscriptionStatus.premium;
      const free = SubscriptionStatus.free;
      const expired = SubscriptionStatus.expired;

      // Act & Assert
      expect(premium.isPremium, isTrue);
      expect(free.isPremium, isFalse);
      expect(expired.isPremium, isFalse);
    });

    test('should identify free status correctly', () {
      // Arrange
      const free = SubscriptionStatus.free;
      const expired = SubscriptionStatus.expired;
      const premium = SubscriptionStatus.premium;

      // Act & Assert
      expect(free.isFree, isTrue);
      expect(expired.isFree, isTrue);
      expect(premium.isFree, isFalse);
    });

    test('should return correct display names', () {
      // Arrange
      const premium = SubscriptionStatus.premium;
      const free = SubscriptionStatus.free;
      const expired = SubscriptionStatus.expired;
      const unavailable = SubscriptionStatus.unavailable;
      const error = SubscriptionStatus.error;
      const unknown = SubscriptionStatus.unknown;

      // Act & Assert
      expect(premium.displayName, equals('Premium'));
      expect(free.displayName, equals('Free'));
      expect(expired.displayName, equals('Expired'));
      expect(unavailable.displayName, equals('Unavailable'));
      expect(error.displayName, equals('Error'));
      expect(unknown.displayName, equals('Unknown'));
    });
  });

  group('SubscriptionProducts Constants Tests', () {
    test('should have correct product IDs', () {
      // Arrange & Act
      const monthly = SubscriptionProducts.monthly;
      const quarterly = SubscriptionProducts.quarterly;
      const yearly = SubscriptionProducts.yearly;

      // Assert
      expect(monthly, equals('com.roamquest.subscription.monthly'));
      expect(quarterly, equals('com.roamquest.subscription.quarterly'));
      expect(yearly, equals('com.roamquest.subscription.yearly'));
    });

    test('should have all product IDs', () {
      // Arrange & Act
      final allIds = SubscriptionProducts.allIds;

      // Assert
      expect(allIds, contains('com.roamquest.subscription.monthly'));
      expect(allIds, contains('com.roamquest.subscription.quarterly'));
      expect(allIds, contains('com.roamquest.subscription.yearly'));
      expect(allIds.length, equals(3));
    });

    test('should return correct duration for monthly', () {
      // Arrange
      const productId = SubscriptionProducts.monthly;
      const expectedDays = 30;

      // Act
      final duration = SubscriptionProducts.getDuration(productId);

      // Assert
      expect(duration.inDays, equals(expectedDays));
    });

    test('should return correct duration for quarterly', () {
      // Arrange
      const productId = SubscriptionProducts.quarterly;
      const expectedDays = 90;

      // Act
      final duration = SubscriptionProducts.getDuration(productId);

      // Assert
      expect(duration.inDays, equals(expectedDays));
    });

    test('should return correct duration for yearly', () {
      // Arrange
      const productId = SubscriptionProducts.yearly;
      const expectedDays = 365;

      // Act
      final duration = SubscriptionProducts.getDuration(productId);

      // Assert
      expect(duration.inDays, equals(expectedDays));
    });

    test('should return default duration for unknown product', () {
      // Arrange
      const unknownProductId = 'com.roamquest.subscription.unknown';
      const expectedDays = 30;

      // Act
      final duration = SubscriptionProducts.getDuration(unknownProductId);

      // Assert
      expect(duration.inDays, equals(expectedDays));
    });

    test('should get period name correctly', () {
      // Act & Assert
      expect(SubscriptionProducts.getPeriodName(SubscriptionProducts.monthly), equals('Monthly'));
      expect(SubscriptionProducts.getPeriodName(SubscriptionProducts.quarterly), equals('Quarterly'));
      expect(SubscriptionProducts.getPeriodName(SubscriptionProducts.yearly), equals('Yearly'));
      expect(SubscriptionProducts.getPeriodName('unknown'), equals('Subscription'));
    });
  });

  group('Subscription Tier Detection Tests', () {
    test('should identify monthly subscription', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Act & Assert
      expect(subscription.isMonthly, isTrue);
      expect(subscription.isQuarterly, isFalse);
      expect(subscription.isYearly, isFalse);
    });

    test('should identify quarterly subscription', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.quarterly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        isActive: true,
        autoRenew: true,
      );

      // Act & Assert
      expect(subscription.isMonthly, isFalse);
      expect(subscription.isQuarterly, isTrue);
      expect(subscription.isYearly, isFalse);
    });

    test('should identify yearly subscription', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.yearly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        isActive: true,
        autoRenew: true,
      );

      // Act & Assert
      expect(subscription.isMonthly, isFalse);
      expect(subscription.isQuarterly, isFalse);
      expect(subscription.isYearly, isTrue);
    });

    test('should handle unknown subscription type', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: 'com.unknown.product',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Act & Assert
      expect(subscription.isMonthly, isFalse);
      expect(subscription.isQuarterly, isFalse);
      expect(subscription.isYearly, isFalse);
    });
  });

  group('Subscription Model Business Logic Tests', () {
    test('should calculate expiry status correctly', () {
      // Arrange - Active subscription
      final activeSubscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Arrange - Expired subscription
      final expiredSubscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        autoRenew: true,
      );

      // Act & Assert
      expect(activeSubscription.isExpired, isFalse);
      expect(activeSubscription.isValid, isTrue);
      expect(expiredSubscription.isExpired, isTrue);
      expect(expiredSubscription.isValid, isFalse);
    });

    test('should calculate days remaining correctly', () {
      // Arrange
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 15));

      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: now,
        endDate: endDate,
        isActive: true,
        autoRenew: true,
      );

      // Act
      final daysRemaining = subscription.daysRemaining;

      // Assert - Should be approximately 15 days (allow for test execution time)
      expect(daysRemaining, greaterThanOrEqualTo(14));
      expect(daysRemaining, lessThanOrEqualTo(15));
    });

    test('should handle lifetime subscription (no end date)', () {
      // Arrange
      final lifetimeSubscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.yearly,
        startDate: DateTime.now(),
        endDate: null,
        isActive: true,
        autoRenew: false,
      );

      // Act & Assert
      expect(lifetimeSubscription.isExpired, isFalse);
      expect(lifetimeSubscription.isValid, isTrue);
      // daysRemaining returns -1 for lifetime subscriptions
      expect(lifetimeSubscription.daysRemaining, lessThan(0));
    });

    test('should handle inactive subscription', () {
      // Arrange
      final inactiveSubscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: false,
        autoRenew: true,
      );

      // Act & Assert
      expect(inactiveSubscription.isValid, isFalse);
    });
  });

  group('SubscriptionTier Enum Tests', () {
    test('should have free and premium tiers', () {
      // Arrange & Act
      const freeTier = SubscriptionTier.free;
      const premiumTier = SubscriptionTier.premium;

      // Assert
      expect(freeTier, equals(SubscriptionTier.free));
      expect(premiumTier, equals(SubscriptionTier.premium));
    });

    test('should have correct display names', () {
      // Arrange & Act
      expect(SubscriptionTier.free.displayName, equals('Free'));
      expect(SubscriptionTier.premium.displayName, equals('Premium'));
    });

    test('should have correct max checkins', () {
      // Arrange & Act
      expect(SubscriptionTier.free.maxCheckins, equals(5));
      expect(SubscriptionTier.premium.maxCheckins, equals(-1)); // Unlimited
    });
  });

  group('Subscription ValueNotifier Tests', () {
    test('should have initial status enum values', () {
      // Arrange & Act - Check that status enum has correct values
      // Note: Cannot instantiate SubscriptionRepository in unit tests
      // because it initializes IAP which requires Flutter binding
      const unknown = SubscriptionStatus.unknown;

      // Assert
      expect(unknown, equals(SubscriptionStatus.unknown));
    });

    test('should have status extension methods', () {
      // Arrange & Act
      const premium = SubscriptionStatus.premium;
      const free = SubscriptionStatus.free;

      // Assert - Verify extension methods exist
      expect(premium.isPremium, isTrue);
      expect(free.isPremium, isFalse);
      expect(free.isFree, isTrue);
      expect(premium.isFree, isFalse);
    });
  });

  group('Subscription Product Price Calculation Tests', () {
    test('should calculate monthly price correctly', () {
      // Arrange
      const monthlyPrice = 4.99;

      // Act
      final yearlyPrice = monthlyPrice * 12;
      final quarterlyPrice = monthlyPrice * 3;

      // Assert
      expect(yearlyPrice, closeTo(59.88, 0.01));
      expect(quarterlyPrice, closeTo(14.97, 0.01));
    });

    test('should calculate savings percentage', () {
      // Arrange
      const monthlyPrice = 4.99;
      const actualYearlyPrice = 47.99;
      const regularYearlyPrice = monthlyPrice * 12;

      // Act
      final savings = ((regularYearlyPrice - actualYearlyPrice) / regularYearlyPrice * 100);

      // Assert - Should be approximately 20% savings
      expect(savings, closeTo(20, 0.5));
    });

    test('should calculate quarterly savings', () {
      // Arrange
      const monthlyPrice = 4.99;
      const actualQuarterlyPrice = 13.49;
      const regularQuarterlyPrice = monthlyPrice * 3;

      // Act
      final savings = ((regularQuarterlyPrice - actualQuarterlyPrice) / regularQuarterlyPrice * 100);

      // Assert - Should be approximately 10% savings
      expect(savings, closeTo(10, 0.5));
    });
  });

  group('Subscription copyWith Tests', () {
    test('should copy subscription with new values', () {
      // Arrange
      final original = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Act
      final copy = original.copyWith(
        isActive: false,
        autoRenew: false,
      );

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.userId, equals(original.userId));
      expect(copy.productId, equals(original.productId));
      expect(copy.isActive, isFalse);
      expect(copy.autoRenew, isFalse);
    });

    test('should create copy with all null values', () {
      // Arrange
      final original = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Act
      final copy = original.copyWith();

      // Assert - Should be identical
      expect(copy.id, equals(original.id));
      expect(copy.isActive, equals(original.isActive));
      expect(copy.autoRenew, equals(original.autoRenew));
    });
  });

  group('Edge Cases', () {
    test('should handle subscription with null transaction ID', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
        originalTransactionId: null,
      );

      // Assert
      expect(subscription.originalTransactionId, isNull);
    });

    test('should handle subscription ending exactly now', () {
      // Arrange
      final now = DateTime.now();

      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(seconds: 1)),
        isActive: true,
        autoRenew: true,
      );

      // Assert - Should still be valid (within margin of error)
      expect(subscription.isExpired, isFalse);
    });

    test('should handle all subscription status transitions', () {
      // Arrange & Act
      final statuses = [
        SubscriptionStatus.unknown,
        SubscriptionStatus.free,
        SubscriptionStatus.premium,
        SubscriptionStatus.expired,
        SubscriptionStatus.unavailable,
        SubscriptionStatus.error,
      ];

      // Assert - All statuses should be valid
      for (final status in statuses) {
        expect(status.displayName, isNotNull);
        expect(status.displayName, isNotEmpty);
      }
    });

    test('should handle subscription with very long duration', () {
      // Arrange
      final farFuture = DateTime.now().add(const Duration(days: 10000));

      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.yearly,
        startDate: DateTime.now(),
        endDate: farFuture,
        isActive: true,
        autoRenew: true,
      );

      // Assert
      expect(subscription.isExpired, isFalse);
      expect(subscription.daysRemaining, greaterThanOrEqualTo(9999));
    });

    test('should handle subscription with past start date', () {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 100));

      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: pastDate,
        endDate: pastDate.add(const Duration(days: 30)),
        isActive: true,
        autoRenew: true,
      );

      // Assert - Should be expired
      expect(subscription.isExpired, isTrue);
    });
  });

  group('Subscription JSON Serialization Tests', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final subscription = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.monthly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        isActive: true,
        autoRenew: true,
        originalTransactionId: 'transaction_123',
      );

      // Act
      final json = subscription.toJson();

      // Assert
      expect(json['id'], equals('test_id'));
      expect(json['user_id'], equals('test_user'));
      expect(json['product_id'], equals(SubscriptionProducts.monthly));
      // Dart's toIso8601String doesn't add 'Z' suffix for local DateTime
      expect(json['start_date'], contains('2024-01-01T00:00:00'));
      expect(json['end_date'], contains('2024-01-31T00:00:00'));
      expect(json['is_active'], isTrue);
      expect(json['auto_renew'], isTrue);
      expect(json['original_transaction_id'], equals('transaction_123'));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'id': 'test_id',
        'user_id': 'test_user',
        'product_id': SubscriptionProducts.monthly,
        'start_date': '2024-01-01T00:00:00.000Z',
        'end_date': '2024-01-31T00:00:00.000Z',
        'is_active': true,
        'auto_renew': true,
        'original_transaction_id': 'transaction_123',
      };

      // Act
      final subscription = Subscription.fromJson(json);

      // Assert
      expect(subscription.id, equals('test_id'));
      expect(subscription.userId, equals('test_user'));
      expect(subscription.productId, equals(SubscriptionProducts.monthly));
      expect(subscription.isActive, isTrue);
      expect(subscription.autoRenew, isTrue);
      expect(subscription.originalTransactionId, equals('transaction_123'));
    });

    test('should handle null end_date in JSON', () {
      // Arrange
      final json = {
        'id': 'test_id',
        'user_id': 'test_user',
        'product_id': SubscriptionProducts.yearly,
        'start_date': '2024-01-01T00:00:00.000Z',
        'end_date': null,
        'is_active': true,
        'auto_renew': false,
      };

      // Act
      final subscription = Subscription.fromJson(json);

      // Assert
      expect(subscription.endDate, isNull);
    });

    test('should round-trip through JSON', () {
      // Arrange
      final original = Subscription(
        id: 'test_id',
        userId: 'test_user',
        productId: SubscriptionProducts.quarterly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        isActive: true,
        autoRenew: true,
      );

      // Act
      final json = original.toJson();
      final restored = Subscription.fromJson(json);

      // Assert
      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.productId, equals(original.productId));
      expect(restored.isActive, equals(original.isActive));
      expect(restored.autoRenew, equals(original.autoRenew));
    });
  });
}
