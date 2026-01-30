import 'package:equatable/equatable.dart';

/// Checklist item model
class ChecklistItem extends Equatable {
  final String id;
  final String title;
  final String location;
  final String category; // landmark, food, experience, hidden
  final int order;
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;
  final double? latitude;
  final double? longitude;
  final int? rating; // User rating 1-20 (stored as int, display as /2.0 for 0.5-10.0 scale)

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.order,
    this.isCompleted = false,
    this.photoUrl,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.rating,
  });

  /// Create from JSON
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      order: json['order'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      rating: json['rating'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'category': category,
      'order': order,
      'is_completed': isCompleted,
      'photo_url': photoUrl,
      'completed_at': completedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
    };
  }

  /// Get display rating (0.5-10.0 scale)
  double? get displayRating => rating != null ? rating! / 2.0 : null;

  /// Create from AI-generated JSON
  factory ChecklistItem.fromAIJson(Map<String, dynamic> json, int order) {
    return ChecklistItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_$order',
      title: json['title'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      order: order,
    );
  }

  /// Create copy with modified fields
  ChecklistItem copyWith({
    String? id,
    String? title,
    String? location,
    String? category,
    int? order,
    bool? isCompleted,
    String? photoUrl,
    DateTime? completedAt,
    double? latitude,
    double? longitude,
    int? rating,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      category: category ?? this.category,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      photoUrl: photoUrl ?? this.photoUrl,
      completedAt: completedAt ?? this.completedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
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

  @override
  List<Object?> get props => [
        id,
        title,
        location,
        category,
        order,
        isCompleted,
        photoUrl,
        completedAt,
        rating,
      ];
}
