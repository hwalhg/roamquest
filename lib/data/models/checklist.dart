import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import 'checklist_item.dart';
import 'city.dart';

/// Checklist model representing either a city checklist or a custom checklist.
class Checklist {
  final String id;
  final int? cityId;
  final City? city;
  final String userId;
  final DateTime createdAt;
  final String language;
  final String source; // city or custom
  final String title;
  final String? description;

  Checklist({
    required this.id,
    this.cityId,
    this.city,
    required this.userId,
    required this.createdAt,
    required this.language,
    this.source = AppConstants.checklistSourceCity,
    String? title,
    this.description,
  }) : title = title ?? city?.name ?? 'Custom Checklist';

  factory Checklist.fromJson(Map<String, dynamic> json) {
    final cityId = json['city_id'] as int?;
    final cityName = json['city_name'] as String?;
    final city = cityId != null || cityName != null
        ? City(
            id: cityId ?? 0,
            name: cityName ?? json['title'] as String? ?? 'Custom Checklist',
            country: json['country'] as String? ?? '',
            countryCode: json['country_code'] as String? ?? 'XX',
            latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
          )
        : null;

    return Checklist(
      id: json['id'] as String,
      cityId: cityId,
      city: city,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: json['language'] as String? ?? 'en',
      source: json['source'] as String? ?? AppConstants.checklistSourceCity,
      title: json['title'] as String? ?? city?.name ?? 'Custom Checklist',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'user_id': userId,
      'city_name': city?.name,
      'country': city?.country,
      'country_code': city?.countryCode,
      'latitude': city?.latitude,
      'longitude': city?.longitude,
      'language': language,
      'source': source,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Checklist.fromAIResponse({
    required City city,
    required List<Map<String, dynamic>> aiItems,
    required String language,
    required String userId,
  }) {
    final checklistId = const Uuid().v4();
    return Checklist(
      id: checklistId,
      cityId: city.id,
      city: city,
      userId: userId,
      createdAt: DateTime.now(),
      language: language,
      source: AppConstants.checklistSourceCity,
      title: city.name,
    );
  }

  factory Checklist.custom({
    required String title,
    required String userId,
    required String language,
    String? description,
  }) {
    return Checklist(
      id: const Uuid().v4(),
      userId: userId,
      createdAt: DateTime.now(),
      language: language,
      source: AppConstants.checklistSourceCustom,
      title: title,
      description: description,
    );
  }

  Checklist copyWith({
    String? id,
    int? cityId,
    bool clearCityId = false,
    City? city,
    bool clearCity = false,
    String? userId,
    DateTime? createdAt,
    String? language,
    String? source,
    String? title,
    String? description,
    bool clearDescription = false,
  }) {
    return Checklist(
      id: id ?? this.id,
      cityId: clearCityId ? null : cityId ?? this.cityId,
      city: clearCity ? null : city ?? this.city,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      source: source ?? this.source,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
    );
  }

  bool get isCustom => source == AppConstants.checklistSourceCustom;
  bool get hasCity => cityId != null && city != null;
  String get displayTitle => title;
  String get displayCountry => city?.country ?? '';
  String get displaySubtitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    if (isCustom) {
      return 'Custom Checklist';
    }
    return city?.country ?? '';
  }

  static List<ChecklistItem> getItemsByCategory(
    String category,
    List<ChecklistItem> items,
  ) {
    if (category == 'all') {
      return items;
    }
    return items.where((item) => item.category == category).toList();
  }

  static List<ChecklistItem> getCompletedItems(List<ChecklistItem> items) {
    return items.where((item) => item.isCompleted).toList();
  }

  static int getCompletedCount(List<ChecklistItem> items) {
    return items.where((item) => item.isCompleted).length;
  }

  static double getProgress(List<ChecklistItem> items) {
    if (items.isEmpty) return 0.0;
    final completedCount = getCompletedCount(items);
    return completedCount / items.length;
  }

  static int getProgressPercentage(List<ChecklistItem> items) {
    return (getProgress(items) * 100).round();
  }

  static List<ChecklistItem> updateItemInList(
    List<ChecklistItem> items,
    ChecklistItem updatedItem,
  ) {
    return items
        .map((item) => item.id == updatedItem.id ? updatedItem : item)
        .toList();
  }

  @override
  String toString() {
    return 'Checklist(id: $id, title: $title, source: $source, cityId: $cityId, userId: $userId)';
  }
}
