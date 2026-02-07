import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/checklist.dart';
import '../models/city.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

/// Service for AI-powered checklist generation
class AIService {
  final Dio _dio = Dio();

  AIService() {
    _dio.options.connectTimeout = ApiConstants.apiTimeout;
    _dio.options.receiveTimeout = ApiConstants.apiTimeout;
  }

  /// Generate a checklist for a city
  Future<Checklist> generateChecklist(
    City city,
    String language,
  ) async {
    try {
      AppLogger.info('Generating checklist for ${city.name}');

      final prompt = PromptTemplates.generateChecklist(
        city.name,
        city.country,
        language,
      );

      // 使用 DeepSeek API
      final response = await _dio.post(
        ApiConstants.deepSeekBaseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.deepSeekApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': ApiConstants.deepSeekModel,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        },
      );

      // Parse DeepSeek response (OpenAI-compatible format)
      final content = response.data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(content);

      if (jsonStr == null) {
        throw AIServiceException('Failed to parse AI response');
      }

      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      final items = jsonData['items'] as List<dynamic>;

      AppLogger.info('Generated ${items.length} items for ${city.name}');

      // Validate items (no longer enforcing 20 items)
      final validatedItems = _validateItems(items);

      return Checklist.fromAIResponse(
        city: city,
        aiItems: validatedItems,
        language: language,
      );
    } on DioException catch (e) {
      AppLogger.error('AI request failed', error: e);
      throw AIServiceException(
        'Failed to generate checklist: ${e.message}',
      );
    } catch (e) {
      AppLogger.error('AI generation failed', error: e);
      throw AIServiceException('Failed to generate checklist: $e');
    }
  }

  /// Extract JSON from AI response
  String? _extractJson(String text) {
    // Find JSON in the response
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final match = jsonPattern.firstMatch(text);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Validate and normalize items
  List<Map<String, dynamic>> _validateItems(List<dynamic> items) {
    final validCategories = ['landmark', 'food', 'experience'];
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
        'title': title.trim(),
        'location': location.trim(),
        'category': category,
      });
    }

    // Return all valid items (no longer enforcing 20 items)
    return result;
  }

  /// Generate checklist with retry logic
  Future<Checklist> generateChecklistWithRetry(
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
