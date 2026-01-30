/// Subscription model
class Subscription {
  final String id;
  final String productId; // monthly or yearly
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool autoRenew;
  final String? originalTransactionId;

  Subscription({
    required this.id,
    required this.productId,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.autoRenew,
    this.originalTransactionId,
  });

  /// Create from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
      autoRenew: json['auto_renew'] as bool? ?? true,
      originalTransactionId: json['original_transaction_id'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'auto_renew': autoRenew,
      'original_transaction_id': originalTransactionId,
    };
  }

  /// Check if subscription is monthly
  bool get isMonthly => productId.contains('monthly');

  /// Check if subscription is yearly
  bool get isYearly => productId.contains('yearly');

  /// Check if subscription is expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if subscription is valid
  bool get isValid => isActive && !isExpired;

  /// Get days remaining
  int get daysRemaining {
    if (endDate == null) return -1; // Lifetime
    return endDate!.difference(DateTime.now()).inDays;
  }

  /// Create copy with modified fields
  Subscription copyWith({
    String? id,
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoRenew,
    String? originalTransactionId,
  }) {
    return Subscription(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
    );
  }
}

/// Subscription tier enum
enum SubscriptionTier {
  free,
  premium,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  int get maxCheckins {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.premium:
        return -1; // Unlimited
    }
  }
}
