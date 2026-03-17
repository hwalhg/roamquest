import 'city.dart';
import 'checklist_item.dart';

/// Checklist model representing a user's list for a city
/// Note: Items are stored in checklist_items table separately
class Checklist {
  final String id;
  final int cityId; // Foreign key to cities table
  final City city; // City object for convenience
  final String userId; // User ID
  final DateTime createdAt;
  final String language;

  Checklist({
    required this.id,
    required this.cityId,
    required this.city,
    required this.userId,
    required this.createdAt,
    required this.language,
  });

  /// Create from JSON
  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] as String,
      cityId: json['city_id'] as int,
      city: City(
        id: json['city_id'] as int,
        name: json['city_name'] as String,
        country: json['country'] as String,
        countryCode: json['country_code'] as String? ?? 'XX',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: json['language'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'user_id': userId,
      'city_name': city.name,
      'country': city.country,
      'country_code': city.countryCode,
      'latitude': city.latitude,
      'longitude': city.longitude,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create from AI response
  factory Checklist.fromAIResponse({
    required City city,
    required List<Map<String, dynamic>> aiItems,
    required String language,
    required String userId,
  }) {
    return Checklist(
      id: 'checklist_${DateTime.now().millisecondsSinceEpoch}',
      cityId: city.id,
      city: city,
      userId: userId,
      createdAt: DateTime.now(),
      language: language,
    );
  }

  /// Create copy with modified fields
  Checklist copyWith({
    String? id,
    int? cityId,
    City? city,
    String? userId,
    DateTime? createdAt,
    String? language,
  }) {
    return Checklist(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      city: city ?? this.city,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
    );
  }

  /// Get items by category (requires items to be provided)
  static List<ChecklistItem> getItemsByCategory(String category, List<ChecklistItem> items) {
    if (category == 'all') {
      return items;
    }
    return items.where((item) => item.category == category).toList();
  }

  /// Get completed items (requires items to be provided)
  static List<ChecklistItem> getCompletedItems(List<ChecklistItem> items) {
    return items.where((item) => item.isCompleted).toList();
  }

  /// Get completed count (requires items to be provided)
  static int getCompletedCount(List<ChecklistItem> items) {
    return items.where((item) => item.isCompleted).length;
  }

  /// Get progress (0.0-1.0) (requires items to be provided)
  static double getProgress(List<ChecklistItem> items) {
    if (items.isEmpty) return 0.0;
    final completedCount = getCompletedCount(items);
    return completedCount / items.length;
  }

  /// Get progress percentage (0-100) (requires items to be provided)
  static int getProgressPercentage(List<ChecklistItem> items) {
    return (getProgress(items) * 100).round();
  }

  /// Update item in items list (requires items to be provided)
  static List<ChecklistItem> updateItemInList(List<ChecklistItem> items, ChecklistItem updatedItem) {
    return items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
  }

  @override
  String toString() =>
      'Checklist(id: $id, cityId: $cityId, userId: $userId)';
}
