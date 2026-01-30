import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API endpoints and configuration
class ApiConstants {
  // DeepSeek AI Configuration (国产大模型)
  static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String deepSeekModel = 'deepseek-chat';

  static String get deepSeekApiKey =>
      dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  // Claude AI Configuration (已停用，改用DeepSeek)
  // static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  // static const String claudeApiVersion = '2023-06-01';
  // static const String claudeModel = 'claude-3-5-sonnet-20241022';
  // static String get claudeApiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Supabase Tables
  static const String tableChecklists = 'checklists';
  static const String tableCheckins = 'checkins';
  static const String tableSubscriptions = 'subscriptions';

  // Supabase Storage
  static const String storagePhotos = 'photos';

  // Mapbox Configuration (disabled)
  // static String get mapboxAccessToken =>
  //     dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  //
  // static String get mapboxStyleUrl =>
  //     dotenv.env['MAPBOX_STYLE_URL'] ?? 'mapbox://styles/mapbox/streets-v12';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// AI Prompt Templates
class PromptTemplates {
  static String generateChecklist(String city, String country, String language) {
    final lang = language == 'zh' ? 'Chinese' : 'English';

    return '''
You are a local travel expert. Generate 20 must-do things in $city, $country.

Include exactly:
- 5 famous landmarks/attractions
- 5 local food/dishes to try
- 5 cultural experiences
- 5 hidden gems (lesser-known spots)

Requirements:
- Each title: maximum 8 words
- Each location: specific name of the place
- Make it exciting and actionable
- Avoid overly touristy traps when possible
- Mix of free and paid activities

Language: $lang

Output ONLY valid JSON in this exact format:
{
  "items": [
    {"title": "Visit the Eiffel Tower", "location": "Eiffel Tower", "category": "landmark"},
    {"title": "Try authentic croissants", "location": "Du Pain et des Idées", "category": "food"},
    {"title": "Take a Seine river cruise", "location": "Seine River", "category": "experience"},
    {"title": "Explore covered passageways", "location": "Passages Couverts", "category": "hidden"}
  ]
}

Ensure exactly 20 items, one per line in the JSON array.
''';
  }

  static String translateText(String text, String targetLanguage) {
    return '''
Translate the following text to ${targetLanguage == 'zh' ? 'Chinese' : 'English'}.
Only return the translation, no explanation.

Text: $text
''';
  }
}
