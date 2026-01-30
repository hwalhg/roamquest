import 'dart:async';
import '../models/city.dart';
import '../repositories/city_repository.dart';
import '../../core/utils/app_logger.dart';

/// Service for managing city data
class CityService {
  final CityRepository _repository = CityRepository();
  static CityService? _instance;
  List<City>? _cachedCities;
  DateTime? _cacheTime;
  static const Duration _cacheExpiration = Duration(hours: 24);

  CityService._internal();

  /// Get singleton instance
  static CityService get instance {
    _instance ??= CityService._internal();
    return _instance!;
  }

  /// Get all active cities sorted by sort_order
  /// Uses cache if available and not expired
  Future<List<City>> getCities({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    if (!forceRefresh &&
        _cachedCities != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheExpiration) {
      AppLogger.info('Returning cached cities');
      return _cachedCities!;
    }

    try {
      AppLogger.info('Fetching cities from database');
      final cities = await _repository.getAllCities();

      // Sort by sort_order
      cities.sort((a, b) => a.name.compareTo(b.name));

      // Update cache
      _cachedCities = cities;
      _cacheTime = DateTime.now();

      AppLogger.info('Loaded ${cities.length} cities');
      return cities;
    } catch (e) {
      AppLogger.error('Failed to get cities', error: e);

      // Return cached data if available, even if expired
      if (_cachedCities != null) {
        AppLogger.warning('Using expired cache due to error');
        return _cachedCities!;
      }

      rethrow;
    }
  }

  /// Search cities by name
  Future<List<City>> searchCities(String query) async {
    final cities = await getCities();
    final lowerQuery = query.toLowerCase();

    return cities
        .where((city) =>
            city.name.toLowerCase().contains(lowerQuery) ||
            city.country.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get city by name and country
  Future<City?> getCityByName(String name, String country) async {
    final cities = await getCities();
    try {
      return cities.firstWhere(
        (city) => city.name == name && city.country == country,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear cache (call after updating cities)
  void clearCache() {
    _cachedCities = null;
    _cacheTime = null;
    AppLogger.info('City cache cleared');
  }
}
