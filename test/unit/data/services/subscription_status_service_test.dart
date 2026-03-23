import 'package:flutter_test/flutter_test.dart';
import 'package:roam_quest/data/models/city.dart';
import 'package:roam_quest/data/models/checklist_item.dart';

import '../../../helpers/test_data.dart';

/// Unit tests for subscription-related logic
/// Note: SubscriptionStatusService requires database connection for full testing
/// These tests cover the logical operations that can be tested without DB
void main() {
  group('Subscription Logic Tests', () {
    group('Free Tier Calculation Logic', () {
      test('should calculate remaining check-ins correctly', () {
        // Arrange
        final completedItems = TestFixtures.createTestItems(
          landmarkCount: 1,
          foodCount: 0,
          experienceCount: 0,
          hiddenCount: 0,
          completed: true,
        );

        // Act - Calculate remaining like the service does
        final landmarkCount = completedItems
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;
        final remainingLandmark = 1 - landmarkCount;

        // Assert
        expect(landmarkCount, 1);
        expect(remainingLandmark, 0);
      });

      test('should return 1 remaining when no items completed', () {
        // Arrange
        final completedItems = <ChecklistItem>[];

        // Act
        final landmarkCount = completedItems
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;
        final remainingLandmark = 1 - landmarkCount;

        // Assert
        expect(landmarkCount, 0);
        expect(remainingLandmark, 1);
      });

      test('should return negative when more than free limit completed', () {
        // Arrange
        final completedItems = TestFixtures.createTestItems(
          landmarkCount: 3,
          foodCount: 0,
          experienceCount: 0,
          hiddenCount: 0,
          completed: true,
        );

        // Act
        final landmarkCount = completedItems
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;
        final remainingLandmark = 1 - landmarkCount;

        // Assert
        expect(landmarkCount, 3);
        expect(remainingLandmark, -2);
      });

      test('should count all categories correctly', () {
        // Arrange
        final completedItems = TestFixtures.createTestItems(
          landmarkCount: 1,
          foodCount: 1,
          experienceCount: 1,
          hiddenCount: 1,
          completed: true,
        );

        // Act
        final landmarkCount = completedItems
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;
        final foodCount = completedItems
            .where((item) => item.category == 'food' && item.isCompleted)
            .length;
        final experienceCount = completedItems
            .where((item) => item.category == 'experience' && item.isCompleted)
            .length;
        final hiddenCount = completedItems
            .where((item) => item.category == 'hidden' && item.isCompleted)
            .length;

        // Assert
        expect(landmarkCount, 1);
        expect(foodCount, 1);
        expect(experienceCount, 1);
        expect(hiddenCount, 1);
      });
    });

    group('City Unlock Logic', () {
      test('should identify free cities correctly', () {
        // Arrange & Act
        final freeCity = TestFixtures.createTestCity(
          name: 'Free City',
          isFree: true,
        );

        // Assert
        expect(freeCity.isFree, true);
        expect(freeCity.isActive, true);
      });

      test('should identify paid cities correctly', () {
        // Arrange & Act
        final paidCity = TestFixtures.createTestCity(
          name: 'Paid City',
          isFree: false,
        );

        // Assert
        expect(paidCity.isFree, false);
      });

      test('should identify inactive cities', () {
        // Arrange & Act
        final inactiveCity = TestFixtures.createTestCity(
          name: 'Inactive City',
          isActive: false,
        );

        // Assert
        expect(inactiveCity.isActive, false);
      });
    });

    group('ChecklistItem Properties', () {
      test('should identify free items correctly', () {
        // Arrange & Act
        final freeItem = ChecklistItem(
          id: 'free_item_1',
          checklistId: 'test_checklist_1',
          title: 'Free Attraction',
          location: 'Test Location',
          category: 'landmark',
          sortOrder: 0,
          isFree: true,
          isCompleted: false,
        );

        // Assert
        expect(freeItem.isFree, true);
        expect(freeItem.isCompleted, false);
      });

      test('should identify paid items correctly', () {
        // Arrange & Act
        final paidItem = ChecklistItem(
          id: 'paid_item_1',
          checklistId: 'test_checklist_1',
          title: 'Paid Attraction',
          location: 'Test Location',
          category: 'landmark',
          sortOrder: 0,
          isFree: false,
          isCompleted: false,
        );

        // Assert
        expect(paidItem.isFree, false);
      });

      test('should identify completed items correctly', () {
        // Arrange & Act
        final completedItem = ChecklistItem(
          id: 'completed_item_1',
          checklistId: 'test_checklist_1',
          title: 'Completed Attraction',
          location: 'Test Location',
          category: 'landmark',
          sortOrder: 0,
          isFree: false,
          isCompleted: true,
          completedAt: DateTime.now(),
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Assert
        expect(completedItem.isCompleted, true);
        expect(completedItem.completedAt, isNotNull);
        expect(completedItem.photoUrl, isNotNull);
      });
    });

    group('Category Filtering', () {
      test('should filter items by category', () {
        // Arrange
        final allItems = TestFixtures.createTestItems(
          landmarkCount: 5,
          foodCount: 3,
          experienceCount: 2,
          hiddenCount: 1,
          completed: false,
        );

        // Act
        final landmarkItems = TestFixtures.getItemsByCategory(allItems, 'landmark');
        final foodItems = TestFixtures.getItemsByCategory(allItems, 'food');
        final experienceItems = TestFixtures.getItemsByCategory(allItems, 'experience');
        final hiddenItems = TestFixtures.getItemsByCategory(allItems, 'hidden');

        // Assert
        expect(landmarkItems.length, 5);
        expect(foodItems.length, 3);
        expect(experienceItems.length, 2);
        expect(hiddenItems.length, 1);
      });

      test('should return empty list for non-existent category', () {
        // Arrange
        final allItems = TestFixtures.createTestItems();

        // Act
        final unknownItems = TestFixtures.getItemsByCategory(allItems, 'unknown');

        // Assert
        expect(unknownItems, isEmpty);
      });

      test('should count completed items by category', () {
        // Arrange
        final items = TestFixtures.createTestItems(
          landmarkCount: 5,
          foodCount: 3,
          experienceCount: 2,
          hiddenCount: 1,
          completed: true,
        );

        // Act
        final counts = TestFixtures.getCompletedCountByCategory(items);

        // Assert
        expect(counts['landmark'], 5);
        expect(counts['food'], 3);
        expect(counts['experience'], 2);
        expect(counts['hidden'], 1);
      });

      test('should return zero for categories with no completed items', () {
        // Arrange
        final items = TestFixtures.createTestItems(completed: false);

        // Act
        final counts = TestFixtures.getCompletedCountByCategory(items);

        // Assert
        expect(counts['landmark'], 0);
        expect(counts['food'], 0);
        expect(counts['experience'], 0);
        expect(counts['hidden'], 0);
      });
    });

    group('Edge Cases', () {
      test('should handle empty items list', () {
        // Arrange
        final emptyItems = <ChecklistItem>[];

        // Act
        final landmarkCount = emptyItems
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;

        // Assert
        expect(landmarkCount, 0);
      });

      test('should handle items with mixed completion status', () {
        // Arrange
        final items = [
          ChecklistItem(
            id: 'item1',
            checklistId: 'checklist1',
            attractionId: 1,
            title: 'Item 1',
            location: 'Location 1',
            category: 'landmark',
            sortOrder: 0,
            isCompleted: true,
          ),
          ChecklistItem(
            id: 'item2',
            checklistId: 'checklist1',
            attractionId: 2,
            title: 'Item 2',
            location: 'Location 2',
            category: 'landmark',
            sortOrder: 1,
            isCompleted: false,
          ),
        ];

        // Act
        final completedCount = items
            .where((item) => item.category == 'landmark' && item.isCompleted)
            .length;
        final totalCount = items.where((item) => item.category == 'landmark').length;

        // Assert
        expect(completedCount, 1);
        expect(totalCount, 2);
      });
    });
  });

  group('TestFixtures Utility Tests', () {
    test('should create test subscription with correct defaults', () {
      // Act
      final subscription = TestFixtures.createTestSubscription();

      // Assert
      expect(subscription.userId, TestFixtures.testUserId);
      expect(subscription.productId, TestFixtures.monthlyProductId);
      expect(subscription.isActive, true);
      expect(subscription.autoRenew, true);
    });

    test('should create test city with correct defaults', () {
      // Act
      final city = TestFixtures.createTestCity();

      // Assert
      expect(city.name, 'San Francisco');
      expect(city.country, 'United States');
      expect(city.isFree, false);
      expect(city.isActive, true);
    });

    test('should create test items with correct count', () {
      // Arrange
      const landmarkCount = 3;
      const foodCount = 2;

      // Act
      final items = TestFixtures.createTestItems(
        landmarkCount: landmarkCount,
        foodCount: foodCount,
        experienceCount: 0,
        hiddenCount: 0,
        completed: false,
      );

      // Assert
      final totalItems = landmarkCount + foodCount;
      expect(items.length, totalItems);
    });

    test('should filter completed items correctly', () {
      // Arrange
      final allItems = TestFixtures.createTestItems(completed: false);
      allItems[0] = allItems[0].copyWith(isCompleted: true);

      // Act
      final completedItems = TestFixtures.getCompletedItems(allItems);

      // Assert
      expect(completedItems.length, 1);
      expect(completedItems.first.isCompleted, true);
    });
  });
}
