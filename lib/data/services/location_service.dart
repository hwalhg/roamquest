import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/city.dart';
import '../../core/utils/app_logger.dart';

/// Service for location-related operations
class LocationService {
  // Debug mode flag - set to true to use mock data
  // Automatically enabled on Web platform due to location API limitations
  static bool _debugMode = kIsWeb; // Enable debug mode on Web

  /// Enable/disable debug mode
  /// When enabled, returns mock data instead of actual GPS
  static setDebugMode(bool enabled) {
    _debugMode = enabled;
    AppLogger.info('LocationService debug mode: ${enabled ? "ENABLED" : "DISABLED"}');
  }

  /// Get debug mode status
  static bool isDebugMode() {
    return _debugMode;
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position
  Future<Position> getCurrentPosition() async {
    // Check if location service is enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are disabled. Please enable them in settings.',
      );
    }

    // Check permission
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionException(
          'Location permissions are denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionException(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    // Get position
    Position position;
    if (_debugMode) {
      // In debug mode, use a mock position
      AppLogger.info('Using mock position for debugging');
      position = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } else {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    AppLogger.info('获取GPS坐标 - 纬度: ${position.latitude}, 经度: ${position.longitude}');

    // 验证坐标范围
    if (position.latitude.abs() > 90) {
      AppLogger.error('无效的纬度: ${position.latitude} (必须在 -90 到 90 之间)');
    }
    if (position.longitude.abs() > 180) {
      AppLogger.error('无效的经度: ${position.longitude} (必须在 -180 到 180 之间)');
    }

    return position;
  }

  /// Get current city
  Future<City> getCurrentCity() async {
    try {
      final position = await getCurrentPosition();
      AppLogger.info('Starting reverse geocoding...');

      // Reverse geocoding
      List<Placemark> placemarks;
      if (_debugMode) {
        // In debug mode, skip geocoding and return mock city
        AppLogger.info('Debug mode: Skipping geocoding, returning mock city');
        return City(
          id: 0, // Temporary ID for debug mode
          name: 'San Francisco',
          country: 'United States',
          countryCode: 'US',
          latitude: 37.7749,
          longitude: -122.4194,
        );
      } else {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      AppLogger.info('Placemarks received: ${placemarks.length}');

      if (placemarks.isEmpty) {
        throw LocationException(
          'Could not find city from location. Please ensure GPS is enabled and try again.',
        );
      }

      final placemark = placemarks.first;

      // Extract city name
      final cityName = placemark.locality ??
          placemark.subAdministrativeArea ??
          placemark.administrativeArea ??
          placemark.name ??
          'Unknown';

      // Extract country
      final country = placemark.country ?? 'Unknown';
      final countryCode = placemark.isoCountryCode ?? 'XX';

      AppLogger.info('Determined city: $cityName, $country');

      return City(
        id: 0, // Temporary ID, will be replaced with actual ID from database
        name: cityName,
        country: country,
        countryCode: countryCode,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceException {
      rethrow;
    } on LocationPermissionException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error getting current city: $e');

      // Provide more specific error message
      String errorMessage = 'Failed to get current city';
      if (e.toString().contains('NOT_FOUND')) {
        errorMessage += ': GPS location unavailable. Please check:';
        errorMessage += '\n1. Ensure Location Services are enabled';
        errorMessage += '\n2. Set a custom location in the simulator (Features → Location → Custom Location)';
      } else if (e.toString().contains('timed out')) {
        errorMessage += ': Request timed out. Please check your internet connection.';
      }

      throw LocationException(errorMessage);
    }
  }

  /// Search for a city by name
  Future<List<City>> searchCity(String query) async {
    try {
      // Get coordinates from address
      final locations = await locationFromAddress(query);

      final cities = <City>[];

      for (final loc in locations) {
        // Use reverse geocoding to get placemark details
        final placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;

          // Extract city name from various possible fields
          final name = placemark.locality ??
              placemark.subAdministrativeArea ??
              placemark.administrativeArea ??
              placemark.name ??
              query;
          final country = placemark.country ?? 'Unknown';
          final countryCode = placemark.isoCountryCode ?? 'XX';

          cities.add(City(
            id: 0, // Temporary ID, will be replaced by actual ID from database
            name: name,
            country: country,
            countryCode: countryCode,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ));
        }
      }

      // Remove duplicates based on name and country
      final uniqueCities = <City>[];
      final seen = <String>{};
      for (final city in cities) {
        final key = '${city.name}_${city.country}';
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueCities.add(city);
        }
      }

      return uniqueCities;
    } catch (e) {
      AppLogger.error('Error searching city: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLatitude,
    );
  }
}

/// Location exceptions
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);

  @override
  String toString() => message;
}
