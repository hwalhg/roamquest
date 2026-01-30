import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/city.dart';
import '../../core/utils/app_logger.dart';

/// Service for location-related operations
class LocationService {
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
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get current city
  Future<City> getCurrentCity() async {
    try {
      final position = await getCurrentPosition();
      AppLogger.info('Got position: ${position.latitude}, ${position.longitude}');

      // Reverse geocoding
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        throw LocationException('Could not determine city from location.');
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
      throw LocationException('Failed to get current city: $e');
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
      endLongitude,
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
