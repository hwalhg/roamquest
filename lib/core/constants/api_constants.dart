import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API endpoints and configuration
class ApiConstants {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Supabase Tables
  static const String tableChecklists = 'checklists';
  static const String tableChecklistItems = 'checklist_items';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableAttractions = 'attractions';

  // Supabase Edge Functions
  static const String fnGenerateChecklist = 'generate-checklist';
  static const String fnVerifyAppStoreSubscription =
      'verify-app-store-subscription';

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
