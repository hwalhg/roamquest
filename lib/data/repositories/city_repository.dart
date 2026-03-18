import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';

/// Repository for city data operations
class CityRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get all active cities (approved cities visible to users)
  Future<List<City>> getAllCities() async {
    try {
      AppLogger.info('Fetching cities from database');

      final response = await _client
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (response.isEmpty) {
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
          .maybeSingle();

      if (response == null) return null;

      return City.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to load city by ID', error: e);
      return null;
    }
  }

  /// Find city by name and country (regardless of is_active status)
  /// 用于检查城市是否已存在于数据库中（包括未审核的）
  Future<City?> findCityByNameAndCountry(String name, String country) async {
    try {
      final response = await _client
          .from('cities')
          .select()
          .eq('name', name)
          .eq('country', country)
          .maybeSingle();

      if (response == null) return null;

      return City.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to find city by name and country', error: e);
      return null;
    }
  }

  /// Create a new city (unapproved by default: is_active=false)
  /// Returns the created city with its ID
  Future<City> createCity(City city) async {
    try {
      AppLogger.info('创建新城市: ${city.name}, ${city.country}');
      AppLogger.info('插入数据库的坐标 - 纬度: ${city.latitude}, 经度: ${city.longitude}');

      final response = await _client
          .from('cities')
          .insert({
            'name': city.name,
            'country': city.country,
            'country_code': city.countryCode,
            'latitude': city.latitude,
            'longitude': city.longitude,
            'is_active': false, // 新城市需要管理员审核
            'sort_order': 0,
          })
          .select()
          .single();

      final createdCity = City.fromJson(response);
      AppLogger.info('Created city with ID: ${createdCity.hashCode}');

      return createdCity;
    } catch (e) {
      AppLogger.error('Failed to create city', error: e);
      rethrow;
    }
  }

  /// Get city by name and country (for use when user locates to a city)
  /// Returns city regardless of is_active status, so checklist can be generated
  Future<City?> getCityByNameAndCountry(String name, String country) async {
    try {
      final response = await _client
          .from('cities')
          .select()
          .eq('name', name)
          .eq('country', country)
          .maybeSingle();

      if (response == null) return null;

      return City.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get city by name and country', error: e);
      return null;
    }
  }
}
