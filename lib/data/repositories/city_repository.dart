import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';

/// Repository for city data operations
class CityRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get all active cities from database
  Future<List<City>> getAllCities() async {
    try {
      AppLogger.info('Fetching cities from database');

      final response = await _client
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (response == null) {
        AppLogger.warning('No cities found in database');
        return [];
      }

      final cities = response.map<City>((data) {
        return City.fromJson(data);
      }).toList();

      AppLogger.info('Loaded ${cities.length} cities from database');
      return cities;
    } catch (e) {
      AppLogger.error('Failed to load cities from database', error: e);
      rethrow;
    }
  }

  /// Get city by ID
  Future<City?> getCityById(int id) async {
    try {
      final response = await _client
          .from('cities')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return City.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to load city by ID', error: e);
      return null;
    }
  }
}
