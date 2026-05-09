import '../models/checklist_item.dart';
import '../models/city.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';

/// Result of AI generation with items
class AIGenerationResult {
  final List<ChecklistItem> items;
  final City city;

  AIGenerationResult({
    required this.items,
    required this.city,
  });
}

/// Service for AI-powered checklist generation
class AIService {
  /// Generate a checklist for a city
  Future<AIGenerationResult> generateChecklist(
    City city,
    String language,
  ) async {
    try {
      AppLogger.info('Generating checklist for ${city.name}');

      final response = await SupabaseConfig.client.functions.invoke(
        ApiConstants.fnGenerateChecklist,
        body: {
          'city_id': city.id,
          'city': city.name,
          'country': city.country,
          'language': language,
        },
      );

      AppLogger.info(
        'Checklist generation response received: status=${response.status}',
      );

      final payload = response.data;
      if (payload is! Map) {
        throw AIServiceException('AI response is not a JSON object');
      }

      final responseItems = payload['items'];
      if (responseItems is! List) {
        final errorMessage = payload['error'] ??
            payload['message'] ??
            'Failed to generate checklist';
        throw AIServiceException(errorMessage.toString());
      }

      AppLogger.info(
        'Generated ${responseItems.length} items for ${city.name}',
      );

      // Validate items (no longer enforcing 20 items)
      final validatedItems = _validateItems(responseItems);

      // Convert to ChecklistItem objects
      final checklistItems = validatedItems
          .asMap()
          .entries
          .map((entry) => ChecklistItem.fromAIJson(entry.value, entry.key))
          .toList();

      // Mark first 2 items of each category as free
      final itemsWithFreeStatus = _markFreeItems(checklistItems);

      return AIGenerationResult(
        items: itemsWithFreeStatus,
        city: city,
      );
    } catch (e) {
      AppLogger.error('AI generation failed', error: e);
      throw AIServiceException('Failed to generate checklist: $e');
    }
  }

  /// Validate and normalize items
  List<Map<String, dynamic>> _validateItems(List<dynamic> items) {
    final validCategories = ['landmark', 'food', 'experience', 'hidden'];
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final title = item['title'] as String?;
      final location = item['location'] as String?;
      final category = item['category'] as String?;

      if (title == null || location == null || category == null) {
        continue;
      }

      // Validate category
      if (!validCategories.contains(category)) {
        continue;
      }

      result.add({
        'attraction_id': item['attraction_id'],
        'title': title.trim(),
        'location': location.trim(),
        'category': category,
        'sort_order': item['sort_order'],
        'is_free': item['is_free'],
        'source': item['source'],
      });
    }

    // Return all valid items (no longer enforcing 20 items)
    return result;
  }

  /// Mark first N items of each category as free
  /// This allows users to try some content before subscribing
  List<ChecklistItem> _markFreeItems(List<ChecklistItem> items) {
    const freeItemsPerCategory = 1;

    // Group items by category and track count
    final categoryCount = <String, int>{};

    return items.map((item) {
      final count = categoryCount[item.category] ?? 0;
      categoryCount[item.category] = count + 1;

      // Mark as free if it's within the free limit for this category
      final isFree = count < freeItemsPerCategory;
      return item.copyWith(isFree: isFree);
    }).toList();
  }

  /// Generate checklist with retry logic
  Future<AIGenerationResult> generateChecklistWithRetry(
    City city,
    String language, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await generateChecklist(city, language);
      } catch (e) {
        attempts++;
        AppLogger.warning(
          'Generation attempt $attempts failed',
        );

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw AIServiceException('Failed after $maxRetries attempts');
  }
}

/// AI service exceptions
class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => message;
}
