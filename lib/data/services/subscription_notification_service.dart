import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing subscription expiry notifications
/// Note: Currently simplified to avoid build issues with flutter_local_notifications
class SubscriptionNotificationService {
  static final SubscriptionNotificationService _instance =
      SubscriptionNotificationService._internal();
  factory SubscriptionNotificationService() => _instance;

  SubscriptionNotificationService._internal();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Show subscription expiry reminder notification
  Future<void> showExpiryReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final endDateStr = prefs.getString('subscription_end_date');
      final isActive = prefs.getBool('subscription_is_active') ?? false;

      if (endDateStr == null || !isActive) return;

      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final daysRemaining = endDate.difference(now).inDays;

      if (daysRemaining <= 3 && daysRemaining > 0) {
        debugPrint('Subscription expiring in $daysRemaining days');
      }
    } catch (e) {
      debugPrint('Error showing expiry reminder: $e');
    }
  }

  /// Show subscription expired notification
  Future<void> showExpiredReminder() async {
    try {
      debugPrint('Subscription expired - show notification');
    } catch (e) {
      debugPrint('Error showing expired reminder: $e');
    }
  }

  /// Cancel all subscription-related notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('Cancelling all notifications');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    debugPrint('Requesting notification permissions');
    return true;
  }

  /// Update notification when subscription changes
  Future<void> onSubscriptionChanged({
    required bool isActive,
    DateTime? endDate,
  }) async {
    if (isActive && endDate != null) {
      await showExpiryReminder();
    } else {
      await cancelAllNotifications();
    }
  }
}
