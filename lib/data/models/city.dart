/// City model representing a geographic location
class City {
  final String name;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final bool isFree; // Whether this city is free to unlock
  final double subscriptionPrice; // Price to unlock this city

  const City({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    this.isFree = false,
    this.subscriptionPrice = 2.99,
  });

  /// Create City from JSON
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      country: json['country'] as String,
      countryCode: json['country_code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isFree: json['is_free'] as bool? ?? false,
      subscriptionPrice: (json['subscription_price'] as num?)?.toDouble() ?? 2.99,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'country_code': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_free': isFree,
      'subscription_price': subscriptionPrice,
    };
  }

  /// Get display name
  String get displayName => '$name, $country';

  /// Create copy with modified fields
  City copyWith({
    String? name,
    String? country,
    String? countryCode,
    double? latitude,
    double? longitude,
    bool? isFree,
    double? subscriptionPrice,
  }) {
    return City(
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFree: isFree ?? this.isFree,
      subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is City &&
        other.name == name &&
        other.country == country &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode => name.hashCode ^ country.hashCode ^ countryCode.hashCode;

  @override
  String toString() => displayName;
}
