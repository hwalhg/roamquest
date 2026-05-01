import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

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
  final bool isFree; // Whether this item is free for all users
  final String source; // official or custom
  final String? photoUrl;
  final DateTime? completedAt;
  final double? spotLatitude;
  final double? spotLongitude;
  final double? checkinLatitude;
  final double? checkinLongitude;
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
    this.isFree = false,
    this.source = AppConstants.checklistItemSourceOfficial,
    this.photoUrl,
    this.completedAt,
    this.spotLatitude,
    this.spotLongitude,
    this.checkinLatitude,
    this.checkinLongitude,
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
      isFree: json['is_free'] as bool? ?? false,
      source: json['source'] as String? ?? AppConstants.checklistItemSourceOfficial,
      photoUrl: json['checkin_photo_url'] as String?,
      completedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      spotLatitude: json['spot_latitude'] != null
          ? (json['spot_latitude'] as num).toDouble()
          : json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      spotLongitude: json['spot_longitude'] != null
          ? (json['spot_longitude'] as num).toDouble()
          : json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
      checkinLatitude: json['checkin_latitude'] != null
          ? (json['checkin_latitude'] as num).toDouble()
          : (json['is_completed'] as bool? ?? false) && json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      checkinLongitude: json['checkin_longitude'] != null
          ? (json['checkin_longitude'] as num).toDouble()
          : (json['is_completed'] as bool? ?? false) &&
                  json['longitude'] != null
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
      'is_free': isFree,
      'source': source,
      'checkin_photo_url': photoUrl,
      'checked_at': completedAt?.toIso8601String(),
      'spot_latitude': spotLatitude,
      'spot_longitude': spotLongitude,
      'checkin_latitude': checkinLatitude,
      'checkin_longitude': checkinLongitude,
      'latitude': checkinLatitude ?? spotLatitude,
      'longitude': checkinLongitude ?? spotLongitude,
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
      attractionId: null,
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
      isFree: attraction['is_free'] as bool? ?? false,
      source:
          attraction['source'] as String? ?? AppConstants.checklistItemSourceOfficial,
      spotLatitude: attraction['spot_latitude'] != null
          ? (attraction['spot_latitude'] as num).toDouble()
          : attraction['latitude'] != null
              ? (attraction['latitude'] as num).toDouble()
              : null,
      spotLongitude: attraction['spot_longitude'] != null
          ? (attraction['spot_longitude'] as num).toDouble()
          : attraction['longitude'] != null
              ? (attraction['longitude'] as num).toDouble()
              : null,
    );
  }

  factory ChecklistItem.customSpot({
    required String checklistId,
    required String title,
    required String location,
    required String category,
    required int sortOrder,
    double? spotLatitude,
    double? spotLongitude,
    String? notes,
  }) {
    final itemId = const Uuid().v4();
    return ChecklistItem(
      id: itemId,
      checklistId: checklistId,
      attractionId: null,
      title: title,
      location: location,
      category: category,
      sortOrder: sortOrder,
      isFree: false,
      source: AppConstants.checklistItemSourceCustom,
      spotLatitude: spotLatitude,
      spotLongitude: spotLongitude,
      notes: notes,
    );
  }

  /// Mark as completed
  ChecklistItem markCompleted({
    required String photoUrl,
    double? checkinLatitude,
    double? checkinLongitude,
    int? rating,
  }) {
    return copyWith(
      isCompleted: true,
      photoUrl: photoUrl,
      completedAt: DateTime.now(),
      checkinLatitude: checkinLatitude,
      checkinLongitude: checkinLongitude,
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
    bool? isFree,
    String? source,
    String? photoUrl,
    DateTime? completedAt,
    double? spotLatitude,
    double? spotLongitude,
    double? checkinLatitude,
    double? checkinLongitude,
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
      isFree: isFree ?? this.isFree,
      source: source ?? this.source,
      photoUrl: photoUrl ?? this.photoUrl,
      completedAt: completedAt ?? this.completedAt,
      spotLatitude: spotLatitude ?? this.spotLatitude,
      spotLongitude: spotLongitude ?? this.spotLongitude,
      checkinLatitude: checkinLatitude ?? this.checkinLatitude,
      checkinLongitude: checkinLongitude ?? this.checkinLongitude,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  /// Alias for backward compatibility
  int get order => sortOrder;
  double? get latitude => spotLatitude;
  double? get longitude => spotLongitude;
  bool get isCustom => source == AppConstants.checklistItemSourceCustom;
  bool get hasSpotCoordinates => spotLatitude != null && spotLongitude != null;
  bool get hasCheckinCoordinates =>
      checkinLatitude != null && checkinLongitude != null;

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
        isFree,
        source,
        photoUrl,
        completedAt,
        spotLatitude,
        spotLongitude,
        checkinLatitude,
        checkinLongitude,
        rating,
        notes,
      ];
}
