import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Checklist item model (stored in checklist_items table)
/// Each item is linked to both a checklist and optionally an attraction template
class ChecklistItem extends Equatable {
  final String id;
  final String checklistId; // Foreign key to checklists table
  final int? attractionId; // Foreign key to attractions table (nullable for custom items)
  final String title;
  final String location;
  final String category; // landmark, food, experience, hidden
  final int sortOrder; // Renamed from 'order' to 'sort_order'
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;
  final double? latitude;
  final double? longitude;
  final int? rating; // User rating 1-10
  final String? notes; // User notes

  const ChecklistItem({
    required this.id,
    required this.checklistId,
    this.attractionId,
    required this.title,
    required this.location,
    required this.category,
    required this.sortOrder,
    this.isCompleted = false,
    this.photoUrl,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.rating,
    this.notes,
  });

  /// Create from JSON
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String,
      attractionId: json['attraction_id'] as int?,
      title: json['title'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      sortOrder: json['sort_order'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
      photoUrl: json['checkin_photo_url'] as String?,
      completedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'attraction_id': attractionId,
      'title': title,
      'location': location,
      'category': category,
      'sort_order': sortOrder,
      'is_completed': isCompleted,
      'checkin_photo_url': photoUrl,
      'checked_at': completedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'notes': notes,
    };
  }

  /// Get display rating (0.5-10.0 scale)
  double? get displayRating => rating != null ? rating! / 1.0 : null;

  /// Create from AI-generated JSON (for new template attractions)
  factory ChecklistItem.fromAIJson(Map<String, dynamic> json, int order) {
    final itemId = const Uuid().v4(); // 生成正确的 UUID
    return ChecklistItem(
      id: itemId,
      checklistId: '', // Placeholder, will be set when saving to checklist
      attractionId: null, // No attraction ID for AI-generated items initially
      title: json['title'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      sortOrder: order,
    );
  }

  /// Create from attractions template
  factory ChecklistItem.fromAttraction({
    required int attractionId,
    required String checklistId,
    required Map<String, dynamic> attraction,
    required int sortOrder,
  }) {
    final itemId = const Uuid().v4(); // 生成正确的 UUID
    return ChecklistItem(
      id: itemId,
      checklistId: checklistId,
      attractionId: attractionId,
      title: attraction['title'] as String,
      location: attraction['location'] as String,
      category: attraction['category'] as String,
      sortOrder: sortOrder,
    );
  }

  /// Mark as completed
  ChecklistItem markCompleted({
    required String photoUrl,
    double? latitude,
    double? longitude,
    int? rating,
  }) {
    return copyWith(
      isCompleted: true,
      photoUrl: photoUrl,
      completedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      rating: rating,
    );
  }

  /// Create copy with modified fields
  ChecklistItem copyWith({
    String? id,
    String? checklistId,
    int? attractionId,
    String? title,
    String? location,
    String? category,
    int? sortOrder,
    bool? isCompleted,
    String? photoUrl,
    DateTime? completedAt,
    double? latitude,
    double? longitude,
    int? rating,
    String? notes,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      attractionId: attractionId ?? this.attractionId,
      title: title ?? this.title,
      location: location ?? this.location,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      photoUrl: photoUrl ?? this.photoUrl,
      completedAt: completedAt ?? this.completedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  /// Alias for backward compatibility
  int get order => sortOrder;

  @override
  List<Object?> get props => [
        id,
        checklistId,
        attractionId,
        title,
        location,
        category,
        sortOrder,
        isCompleted,
        photoUrl,
        completedAt,
        latitude,
        longitude,
        rating,
        notes,
      ];
}
