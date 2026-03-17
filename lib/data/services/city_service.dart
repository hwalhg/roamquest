import 'dart:async';
import '../models/city.dart';
import '../repositories/city_repository.dart';
import '../../core/utils/app_logger.dart';

/// Chinese to English city name mapping
const Map<String, String> _cityNameMapping = {
  '北京市': 'Beijing',
  '上海': 'Shanghai',
  '上海市': 'Shanghai',
  '广州': 'Guangzhou',
  '广州市': 'Guangzhou',
  '深圳': 'Shenzhen',
  '深圳市': 'Shenzhen',
  '杭州': 'Hangzhou',
  '杭州市': 'Hangzhou',
  '成都': 'Chengdu',
  '成都市': 'Chengdu',
  '重庆': 'Chongqing',
  '重庆市': 'Chongqing',
  '武汉': 'Wuhan',
  '武汉市': 'Wuhan',
  '西安': 'Xi\'an',
  '西安市': 'Xi\'an',
  '南京': 'Nanjing',
  '南京市': 'Nanjing',
  '天津': 'Tianjin',
  '天津市': 'Tianjin',
  '苏州': 'Suzhou',
  '苏州市': 'Suzhou',
  '长沙': 'Changsha',
  '长沙市': 'Changsha',
  '郑州': 'Zhengzhou',
  '郑州市': 'Zhengzhou',
  '沈阳': 'Shenyang',
  '沈阳市': 'Shenyang',
  '青岛': 'Qingdao',
  '青岛市': 'Qingdao',
  '大连': 'Dalian',
  '大连市': 'Dalian',
  '厦门': 'Xiamen',
  '厦门市': 'Xiamen',
  '宁波': 'Ningbo',
  '宁波市': 'Ningbo',
  '香港': 'Hong Kong',
  '澳门': 'Macau',
  '台北市': 'Taipei',
  '台湾': 'Taiwan',
  'United States': 'United States',
  '美国': 'United States',
  '英国': 'United Kingdom',
  'Japan': 'Japan',
  '日本': 'Japan',
  '韩国': 'South Korea',
  'France': 'France',
  '法国': 'France',
  'Germany': 'Germany',
  '德国': 'Germany',
  'Italy': 'Italy',
  '意大利': 'Italy',
  'Spain': 'Spain',
  '西班牙': 'Spain',
  'Australia': 'Australia',
  '澳大利亚': 'Australia',
  'Canada': 'Canada',
  '加拿大': 'Canada',
  'Singapore': 'Singapore',
  '新加坡': 'Singapore',
};

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

  /// Get all active and approved cities sorted by sort_order
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

      // Sort by name
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

  /// Get city by name and country from approved cities cache
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

  /// Find or create a city by name and country
  /// 当用户定位到城市时调用此方法：
  /// 1. 如果城市存在（无论 is_active 状态），返回该城市
  /// 2. 如果城市不存在，尝试翻译中文名后再次查找
  /// 3. 如果仍然不存在，创建新城市（需要 RLS 策略允许）
  Future<City> findOrCreateCity(String name, String country, String countryCode, double latitude, double longitude) async {
    AppLogger.info('findOrCreateCity called with: name="$name", country="$country", countryCode="$countryCode"');

    // Try to find existing city with original name (regardless of is_active status)
    AppLogger.info('Searching for city with original name: "$name", "$country"');
    final existingCity = await _repository.findCityByNameAndCountry(name, country);

    if (existingCity != null) {
      AppLogger.info('Found existing city: $name, $country');
      return existingCity;
    }

    AppLogger.info('City not found with original name. Checking mapping...');

    // Not found with original name, try to translate Chinese city name to English
    final englishName = _cityNameMapping[name];
    final englishCountry = _cityNameMapping[country];

    AppLogger.info('Mapping lookup - englishName: $englishName, englishCountry: $englishCountry');

    if (englishName != null || englishCountry != null) {
      final searchName = englishName ?? name;
      final searchCountry = englishCountry ?? country;

      AppLogger.info('Translating city name: "$name, $country" -> "$searchName, $searchCountry"');
      final translatedCity = await _repository.findCityByNameAndCountry(searchName, searchCountry);

      if (translatedCity != null) {
        AppLogger.info('Found city after translation: $searchName, $searchCountry');
        return translatedCity;
      }
    }

    // 城市不存在，创建新城市
    AppLogger.info('创建新城市: $name, $country');
    AppLogger.info('新城市坐标 - 纬度: $latitude, 经度: $longitude');
    final newCity = City(
      id: 0, // Placeholder ID, will be replaced with actual ID from database
      name: englishName ?? name,
      country: englishCountry ?? country,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
    );

    return await _repository.createCity(newCity);
  }

  /// Clear cache (call after updating cities)
  void clearCache() {
    _cachedCities = null;
    _cacheTime = null;
    AppLogger.info('City cache cleared');
  }
}
