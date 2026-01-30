import 'city.dart';
import 'checklist_item.dart';

/// Checklist model representing a city's must-do list
class Checklist {
  final String id;
  final City city;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final String language;

  Checklist({
    required this.id,
    required this.city,
    required this.items,
    required this.createdAt,
    required this.language,
  });

  /// Create from JSON
  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] as String,
      city: City.fromJson(json['city'] as Map<String, dynamic>),
      items: (json['items'] as List)
          .map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      language: json['language'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'language': language,
    };
  }

  /// Create from AI response
  factory Checklist.fromAIResponse({
    required City city,
    required List<Map<String, dynamic>> aiItems,
    required String language,
  }) {
    final items = aiItems
        .asMap()
        .entries
        .map((entry) => ChecklistItem.fromAIJson(entry.value, entry.key))
        .toList();

    return Checklist(
      id: 'checklist_${DateTime.now().millisecondsSinceEpoch}',
      city: city,
      items: items,
      createdAt: DateTime.now(),
      language: language,
    );
  }

  /// Get completed items
  List<ChecklistItem> get completedItems =>
      items.where((item) => item.isCompleted).toList();

  /// Get pending items
  List<ChecklistItem> get pendingItems =>
      items.where((item) => !item.isCompleted).toList();

  /// Get items by category
  List<ChecklistItem> getItemsByCategory(String category) =>
      items.where((item) => item.category == category).toList();

  /// Get completion count
  int get completedCount => completedItems.length;

  /// Get progress (0.0 to 1.0)
  double get progress => items.isEmpty ? 0.0 : completedCount / items.length;

  /// Get progress percentage
  int get progressPercentage => (progress * 100).round();

  /// Check if all items are completed
  bool get isComplete => progress >= 1.0;

  /// Check if can add more check-ins (free tier limit)
  bool get canAddMoreCheckins => completedCount < 5;

  /// Get items sorted by category
  Map<String, List<ChecklistItem>> get itemsByCategory {
    final result = <String, List<ChecklistItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.category, () => []).add(item);
    }
    return result;
  }

  /// Create copy with modified fields
  Checklist copyWith({
    String? id,
    City? city,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    String? language,
  }) {
    return Checklist(
      id: id ?? this.id,
      city: city ?? this.city,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
    );
  }

  /// Update item in checklist
  Checklist updateItem(ChecklistItem updatedItem) {
    return copyWith(
      items: items
          .map((item) => item.id == updatedItem.id ? updatedItem : item)
          .toList(),
    );
  }

  @override
  String toString() =>
      'Checklist(id: $id, city: ${city.name}, completed: $completedCount/${items.length})';
}
