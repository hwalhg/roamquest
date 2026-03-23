import 'package:flutter_test/flutter_test.dart';
import 'package:roam_quest/data/models/subscription.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('Subscription Model Tests', () {
    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'test_id',
          userId: 'user_123',
          productId: TestFixtures.monthlyProductId,
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          isActive: true,
          autoRenew: true,
          originalTransactionId: 'transaction_123',
        );

        // Act
        final json = subscription.toJson();

        // Assert
        expect(json['id'], 'test_id');
        expect(json['user_id'], 'user_123');
        expect(json['product_id'], TestFixtures.monthlyProductId);
        expect(json['start_date'], now.toIso8601String());
        expect(json['end_date'], now.add(const Duration(days: 30)).toIso8601String());
        expect(json['is_active'], true);
        expect(json['auto_renew'], true);
        expect(json['original_transaction_id'], 'transaction_123');
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final now = DateTime.now();
        final json = {
          'id': 'test_id',
          'user_id': 'user_123',
          'product_id': TestFixtures.monthlyProductId,
          'start_date': now.toIso8601String(),
          'end_date': now.add(const Duration(days: 30)).toIso8601String(),
          'is_active': true,
          'auto_renew': true,
          'original_transaction_id': 'transaction_123',
        };

        // Act
        final subscription = Subscription.fromJson(json);

        // Assert
        expect(subscription.id, 'test_id');
        expect(subscription.userId, 'user_123');
        expect(subscription.productId, TestFixtures.monthlyProductId);
        expect(subscription.startDate, now);
        expect(subscription.endDate, now.add(const Duration(days: 30)));
        expect(subscription.isActive, true);
        expect(subscription.autoRenew, true);
        expect(subscription.originalTransactionId, 'transaction_123');
      });

      test('should handle null end_date in JSON', () {
        // Arrange
        final now = DateTime.now();
        final json = {
          'id': 'test_id',
          'user_id': 'user_123',
          'product_id': TestFixtures.yearlyProductId,
          'start_date': now.toIso8601String(),
          'end_date': null,
          'is_active': true,
          'auto_renew': false,
          'original_transaction_id': null,
        };

        // Act
        final subscription = Subscription.fromJson(json);

        // Assert
        expect(subscription.endDate, null);
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final now = DateTime.now();
        final json = {
          'id': 'test_id',
          'user_id': 'user_123',
          'product_id': TestFixtures.monthlyProductId,
          'start_date': now.toIso8601String(),
          'end_date': null,
          'is_active': null,
          'auto_renew': null,
        };

        // Act
        final subscription = Subscription.fromJson(json);

        // Assert
        expect(subscription.isActive, false); // defaults to false
        expect(subscription.autoRenew, true); // defaults to true
      });
    });

    group('Subscription Type Detection', () {
      test('should identify monthly subscription', () {
        // Arrange & Act
        final subscription = TestFixtures.createTestSubscription(
          productId: TestFixtures.monthlyProductId,
        );

        // Assert
        expect(subscription.isMonthly, true);
        expect(subscription.isQuarterly, false);
        expect(subscription.isYearly, false);
      });

      test('should identify quarterly subscription', () {
        // Arrange & Act
        final subscription = TestFixtures.createTestSubscription(
          productId: TestFixtures.quarterlyProductId,
        );

        // Assert
        expect(subscription.isMonthly, false);
        expect(subscription.isQuarterly, true);
        expect(subscription.isYearly, false);
      });

      test('should identify yearly subscription', () {
        // Arrange & Act
        final subscription = TestFixtures.createTestSubscription(
          productId: TestFixtures.yearlyProductId,
        );

        // Assert
        expect(subscription.isMonthly, false);
        expect(subscription.isQuarterly, false);
        expect(subscription.isYearly, true);
      });
    });

    group('Expiration Status', () {
      test('should be expired when end date is in the past', () {
        // Arrange & Act
        final subscription = TestFixtures.createExpiredSubscription();

        // Assert
        expect(subscription.isExpired, true);
        expect(subscription.isValid, false);
      });

      test('should not be expired when end date is in the future', () {
        // Arrange & Act
        final subscription = TestFixtures.createValidMonthlySubscription();

        // Assert
        expect(subscription.isExpired, false);
      });

      test('should not be expired when end date is null (lifetime)', () {
        // Arrange & Act
        final subscription = TestFixtures.createLifetimeSubscription();

        // Assert
        expect(subscription.isExpired, false);
      });

      test('should be valid when active and not expired', () {
        // Arrange & Act
        final subscription = TestFixtures.createValidMonthlySubscription();

        // Assert
        expect(subscription.isValid, true);
      });

      test('should not be valid when inactive', () {
        // Arrange & Act
        final subscription = TestFixtures.createInactiveSubscription();

        // Assert
        expect(subscription.isValid, false);
      });

      test('should not be valid when expired', () {
        // Arrange & Act
        final subscription = TestFixtures.createExpiredSubscription();

        // Assert
        expect(subscription.isActive, true); // Still marked active
        expect(subscription.isValid, false); // But not valid due to expiration
      });
    });

    group('Days Remaining', () {
      test('should calculate days remaining correctly', () {
        // Arrange
        final now = DateTime.now();
        final endDate = now.add(const Duration(days: 15));
        final subscription = TestFixtures.createTestSubscription(
          endDate: endDate,
        );

        // Act
        final daysRemaining = subscription.daysRemaining;

        // Assert
        expect(daysRemaining, greaterThanOrEqualTo(14)); // Allow for test execution time
        expect(daysRemaining, lessThanOrEqualTo(15));
      });

      test('should return -1 for lifetime subscription', () {
        // Arrange & Act
        final subscription = TestFixtures.createLifetimeSubscription();

        // Assert
        expect(subscription.daysRemaining, -1);
      });

      test('should return negative days when expired', () {
        // Arrange & Act
        final subscription = TestFixtures.createExpiredSubscription();

        // Assert
        expect(subscription.daysRemaining, lessThan(0));
      });
    });

    group('copyWith Method', () {
      test('should copy subscription with new values', () {
        // Arrange
        final original = TestFixtures.createTestSubscription();
        const newUserId = 'new_user_456';

        // Act
        final copy = original.copyWith(userId: newUserId);

        // Assert
        expect(copy.userId, newUserId);
        expect(copy.id, original.id);
        expect(copy.productId, original.productId);
        expect(copy.startDate, original.startDate);
        expect(copy.isActive, original.isActive);
      });

      test('should copy all fields when all parameters provided', () {
        // Arrange
        final original = TestFixtures.createTestSubscription();
        final newEndDate = DateTime(2025, 12, 31);

        // Act
        final copy = original.copyWith(
          id: 'new_id',
          userId: 'new_user',
          productId: TestFixtures.yearlyProductId,
          startDate: DateTime(2024, 1, 1),
          endDate: newEndDate,
          isActive: false,
          autoRenew: false,
          originalTransactionId: 'new_transaction',
        );

        // Assert
        expect(copy.id, 'new_id');
        expect(copy.userId, 'new_user');
        expect(copy.productId, TestFixtures.yearlyProductId);
        expect(copy.startDate, DateTime(2024, 1, 1));
        expect(copy.endDate, newEndDate);
        expect(copy.isActive, false);
        expect(copy.autoRenew, false);
        expect(copy.originalTransactionId, 'new_transaction');
      });

      test('should maintain original values when no parameters provided', () {
        // Arrange
        final original = TestFixtures.createTestSubscription();

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.productId, original.productId);
        expect(copy.startDate, original.startDate);
        expect(copy.endDate, original.endDate);
        expect(copy.isActive, original.isActive);
        expect(copy.autoRenew, original.autoRenew);
        expect(copy.originalTransactionId, original.originalTransactionId);
      });
    });

    group('Edge Cases', () {
      test('should handle subscription created just now', () {
        // Arrange & Act
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'test_now',
          userId: 'user_now',
          productId: TestFixtures.monthlyProductId,
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          isActive: true,
          autoRenew: true,
        );

        // Assert
        expect(subscription.isExpired, false);
        expect(subscription.daysRemaining, greaterThanOrEqualTo(29));
        expect(subscription.isValid, true);
      });

      test('should handle subscription ending exactly now', () {
        // Arrange
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'test_exact',
          userId: 'user_exact',
          productId: TestFixtures.monthlyProductId,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now.add(const Duration(seconds: 1)), // Ends in 1 second
          isActive: true,
          autoRenew: true,
        );

        // Act & Assert
        // Should not be expired since endDate is 1 second in the future
        expect(subscription.isExpired, isFalse);
      });

      test('should handle empty product ID gracefully', () {
        // Arrange & Act
        final subscription = TestFixtures.createTestSubscription(
          productId: '',
        );

        // Assert
        expect(subscription.isMonthly, false);
        expect(subscription.isQuarterly, false);
        expect(subscription.isYearly, false);
      });

      test('should handle product ID with similar names', () {
        // Arrange & Act
        final subscription = TestFixtures.createTestSubscription(
          productId: 'com.other.subscription.monthly.premium',
        );

        // Assert
        expect(subscription.isMonthly, true); // Contains 'monthly'
      });
    });
  });

  group('SubscriptionTier Extension Tests', () {
    test('Free tier should have correct display name', () {
      // Act
      final displayName = SubscriptionTier.free.displayName;

      // Assert
      expect(displayName, 'Free');
    });

    test('Premium tier should have correct display name', () {
      // Act
      final displayName = SubscriptionTier.premium.displayName;

      // Assert
      expect(displayName, 'Premium');
    });

    test('Free tier should have max checkins of 5', () {
      // Act
      final maxCheckins = SubscriptionTier.free.maxCheckins;

      // Assert
      expect(maxCheckins, 5);
    });

    test('Premium tier should have unlimited checkins (-1)', () {
      // Act
      final maxCheckins = SubscriptionTier.premium.maxCheckins;

      // Assert
      expect(maxCheckins, -1);
    });
  });
}
