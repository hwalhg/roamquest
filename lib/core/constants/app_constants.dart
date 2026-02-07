/// Core application constants
class AppConstants {
  // App Info
  static const String appName = 'RoamQuest';
  static const String appVersion = '1.0.0';

  // Free Tier Limits
  static const int freeCheckinLimit = 5;

  // Checklist Configuration
  static const int checklistItemCount = 20;

  // Categories
  static const List<String> categories = [
    'landmark', // 著名景点
    'food',     // 特色美食
    'experience', // 文化体验
  ];

  // Category Colors (for UI)
  static const Map<String, String> categoryColors = {
    'landmark': '#FF6B6B',
    'food': '#4ECDC4',
    'experience': '#45B7D1',
  };

  // Category Icons (emoji for simplicity)
  static const Map<String, String> categoryIcons = {
    'landmark': '🏛️',
    'food': '🍜',
    'experience': '🎭',
  };

  // Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keySelectedLanguage = 'selected_language';
  static const String keyCurrentChecklistId = 'current_checklist_id';

  // Cache Duration
  static const int checklistCacheHours = 24;
  static const int imageCacheDays = 7;

  // Report Configuration
  static const int reportPhotoGridColumns = 3;
  static const double reportMapZoom = 12.0;

  // Animation Durations
  static const int animationDurationMs = 300;
  static const int listAnimationStaggerMs = 50;
}

/// Subscription Product IDs
/// City-based permanent unlock: com.roamquest.city.{city_id}
class SubscriptionProducts {
  /// Generate product ID for a city
  static String getCityProductId(String cityName) {
    // Sanitize city name for product ID
    final sanitized = cityName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return 'com.roamquest.city.$sanitized';
  }

  /// Legacy monthly/weekly subscriptions (deprecated, kept for reference)
  static const String monthly = 'com.roamquest.subscription.monthly';
  static const String yearly = 'com.roamquest.subscription.yearly';

  static List<String> get allIds => [monthly, yearly];
}

/// Supported Languages
class AppLanguages {
  static const String english = 'en';
  static const String chinese = 'zh';
  static const List<String> supported = [english, chinese];

  static String getLanguageName(String code) {
    switch (code) {
      case english:
        return 'English';
      case chinese:
        return '中文';
      default:
        return 'English';
    }
  }
}
