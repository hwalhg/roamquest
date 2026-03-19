/// Core application constants
class AppConstants {
  // App Info
  static const String appName = 'RoamQuest';
  static const String appVersion = '1.0.0';

  // Free Tier Limits (removed - using per-category limits in SubscriptionStatusService)
  // Each category (landmark, food, experience, hidden) has 1 free check-in

  // Checklist Configuration
  static const int checklistItemCount = 20;

  // Categories
  static const List<String> categories = [
    'landmark', // 著名景点
    'food',     // 特色美食
    'experience', // 文化体验
    'hidden',    // 隐藏宝藏
  ];

  // Category Colors (for UI)
  static const Map<String, String> categoryColors = {
    'landmark': '#FF6B6B',
    'food': '#4ECDC4',
    'experience': '#45B7D1',
    'hidden': '#96CEB4',
  };

  // Category Icons (emoji for simplicity)
  static const Map<String, String> categoryIcons = {
    'landmark': '🏛️',
    'food': '🍜',
    'experience': '🎭',
    'hidden': '💎',
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
/// Global subscription - unlocks all cities for a period of time
class SubscriptionProducts {
  // Auto-renewable subscriptions
  static const String monthly = 'com.roamquest.subscription.monthly';
  static const String quarterly = 'com.roamquest.subscription.quarterly';
  static const String yearly = 'com.roamquest.subscription.yearly';

  /// All subscription product IDs
  static List<String> get allIds => [monthly, quarterly, yearly];

  /// Subscription period display names
  static String getPeriodName(String productId) {
    switch (productId) {
      case monthly:
        return 'Monthly';
      case quarterly:
        return 'Quarterly';
      case yearly:
        return 'Yearly';
      default:
        return 'Subscription';
    }
  }

  /// Get duration for each subscription type
  static Duration getDuration(String productId) {
    switch (productId) {
      case monthly:
        return const Duration(days: 30);
      case quarterly:
        return const Duration(days: 90);
      case yearly:
        return const Duration(days: 365);
      default:
        return const Duration(days: 30);
    }
  }
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
