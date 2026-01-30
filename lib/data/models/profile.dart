/// User profile model
class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    Map<String, dynamic>? preferences,
    required this.createdAt,
    required this.updatedAt,
  }) : preferences = preferences ?? {};

  /// Create profile from JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Profile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if profile has a username set
  bool get hasUsername => username != null && username!.isNotEmpty;

  /// Get display name (fallback to email part or "User")
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (username != null && username!.isNotEmpty) return username!;
    return 'Traveler';
  }

  /// Check if user is premium
  bool get isPremium => preferences['is_premium'] == true;

  /// Get subscription tier
  String get subscriptionTier => preferences['subscription_tier'] ?? 'free';
}
