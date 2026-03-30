import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import '../services/subscription_notification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';

/// Repository for managing subscriptions
class SubscriptionRepository {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Subscription state
  final ValueNotifier<SubscriptionStatus> status = ValueNotifier(
    SubscriptionStatus.unknown,
  );

  final ValueNotifier<List<ProductDetails>> products = ValueNotifier([]);

  /// Initialize subscription service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing subscription service...');

      // Check if in-app purchase is available
      final isAvailable = await _iap.isAvailable();
      AppLogger.info('IAP Available: $isAvailable');

      if (!isAvailable) {
        AppLogger.warning('In-app purchase not available');
        status.value = SubscriptionStatus.unavailable;
        return;
      }

      // Initialize notification service
      await SubscriptionNotificationService().initialize();

      // Listen to purchase updates
      final purchaseStream = _iap.purchaseStream;
      _subscription = purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );
      AppLogger.info('Purchase stream listener registered');

      // Load products
      await loadProducts();

      // Check existing subscription
      await checkSubscriptionStatus();

      AppLogger.info('Subscription service initialized. Status: ${status.value}');
    } catch (e) {
      // Web platform or other error - in-app purchase not available
      AppLogger.warning('In-app purchase not available on this platform: $e');
      status.value = SubscriptionStatus.unavailable;
    }
  }

  /// Load available products
  Future<void> loadProducts() async {
    try {
      AppLogger.info('Loading products: ${SubscriptionProducts.allIds}');
      AppLogger.info('Querying App Store for product details...');

      final response = await _iap.queryProductDetails(
        SubscriptionProducts.allIds.toSet(),
      );

      AppLogger.info('Query response received');
      AppLogger.info('  - Product details found: ${response.productDetails.length}');
      AppLogger.info('  - Not found IDs: ${response.notFoundIDs}');
      AppLogger.info('  - Error: ${response.error?.message ?? "None"}');

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('Products not found: ${response.notFoundIDs}');
        AppLogger.warning('Please check App Store Connect to ensure these products exist');
      }

      if (response.productDetails.isEmpty) {
        AppLogger.error('No products found. Error: ${response.error?.message ?? "Unknown"}');
        AppLogger.error('This usually means:');
        AppLogger.error('  1. Products not configured in App Store Connect');
        AppLogger.error('  2. Bundle ID mismatch between app and App Store Connect');
        AppLogger.error('  3. Not signed in to App Store on device');
        AppLogger.error('  4. Products not yet approved (may take 15-30 minutes after creation)');
        status.value = SubscriptionStatus.error;
      } else {
        products.value = response.productDetails.toList();
        AppLogger.info('Loaded ${products.value.length} products:');
        for (final p in products.value) {
          AppLogger.info('  - ${p.id}: ${p.title} (${p.price})');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load products', error: e, stackTrace: stackTrace);
      if (e.toString().contains('No active account')) {
        AppLogger.warning('No active App Store account. Please sign in to App Store in Settings');
      }
      status.value = SubscriptionStatus.error;
    }
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase (server-side in production)
        await _verifyPurchase(purchase);

        // Save subscription
        await _saveSubscription(
          productId: purchase.productID,
          transactionId: purchase.purchaseID,
        );

        status.value = SubscriptionStatus.premium;
        AppLogger.info('Purchase successful: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        AppLogger.error('Purchase error: ${purchase.error}');
        status.value = SubscriptionStatus.error;
      } else if (purchase.status == PurchaseStatus.canceled) {
        status.value = SubscriptionStatus.free;
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } catch (e) {
      AppLogger.error('Error handling purchase', error: e);
      status.value = SubscriptionStatus.error;
    }
  }

  /// Verify purchase with server (in production)
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    // In production, verify with your backend
    // For now, we'll accept local verification
    AppLogger.info('Verifying purchase: ${purchase.productID}');
  }

  /// Save subscription locally
  Future<void> _saveSubscription({
    required String productId,
    required String? transactionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Calculate expiry date based on subscription type
      final now = DateTime.now();
      final duration = SubscriptionProducts.getDuration(productId);
      final expiry = now.add(duration);

      await prefs.setString('subscription_product_id', productId);
      await prefs.setString('subscription_transaction_id', transactionId ?? '');
      await prefs.setString('subscription_start_date', now.toIso8601String());
      await prefs.setString('subscription_end_date', expiry.toIso8601String());
      await prefs.setBool('subscription_is_active', true);

      AppLogger.info('Subscription saved: $productId (expires: $expiry)');

      // Schedule expiry notification
      await SubscriptionNotificationService()
          .onSubscriptionChanged(isActive: true, endDate: expiry);
    } catch (e) {
      AppLogger.error('Failed to save subscription', error: e);
    }
  }

  /// Check subscription status from local storage
  Future<void> checkSubscriptionStatus() async {
    // Don't override error status from loadProducts()
    if (status.value == SubscriptionStatus.error) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('subscription_is_active') ?? false;
      final endDateStr = prefs.getString('subscription_end_date');

      if (!isActive || endDateStr == null) {
        status.value = SubscriptionStatus.free;
        return;
      }

      final endDate = DateTime.parse(endDateStr);
      if (DateTime.now().isAfter(endDate)) {
        // Subscription expired
        status.value = SubscriptionStatus.expired;
        await clearSubscription();
      } else {
        status.value = SubscriptionStatus.premium;
      }
    } catch (e) {
      AppLogger.error('Failed to check subscription', error: e);
      status.value = SubscriptionStatus.free;
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final productDetails = products.value;
      final product = productDetails.firstWhere(
        (p) => p.id == productId,
      );

      final purchaseParam = PurchaseParam(productDetails: product);
      // Use buyNonConsumable for auto-renewable subscriptions on iOS
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      return result;
    } catch (e) {
      AppLogger.error('Failed to purchase', error: e);
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      AppLogger.info('Restoring purchases');
    } catch (e) {
      AppLogger.error('Failed to restore', error: e);
      status.value = SubscriptionStatus.error;
    }
  }

  /// Clear subscription
  Future<void> clearSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('subscription_product_id');
      await prefs.remove('subscription_transaction_id');
      await prefs.remove('subscription_start_date');
      await prefs.remove('subscription_end_date');
      await prefs.remove('subscription_is_active');

      status.value = SubscriptionStatus.free;
      AppLogger.info('Subscription cleared');

      // Cancel expiry notifications
      await SubscriptionNotificationService().cancelAllNotifications();
    } catch (e) {
      AppLogger.error('Failed to clear subscription', error: e);
    }
  }

  /// Get subscription details
  Future<Subscription?> getSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productId = prefs.getString('subscription_product_id');
      final transactionId = prefs.getString('subscription_transaction_id');
      final startDateStr = prefs.getString('subscription_start_date');
      final endDateStr = prefs.getString('subscription_end_date');
      final isActive = prefs.getBool('subscription_is_active') ?? false;

      if (productId == null || startDateStr == null) {
        return null;
      }

      return Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user', // Placeholder - actual userId should come from auth service
        productId: productId,
        startDate: DateTime.parse(startDateStr),
        endDate: endDateStr != null ? DateTime.parse(endDateStr) : null,
        isActive: isActive,
        autoRenew: true, // Default to true for iOS
        originalTransactionId: transactionId,
      );
    } catch (e) {
      AppLogger.error('Failed to get subscription', error: e);
      return null;
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    AppLogger.error('Purchase stream error', error: error);
    status.value = SubscriptionStatus.error;
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
    status.dispose();
    products.dispose();
  }
}

/// Subscription status enum
enum SubscriptionStatus {
  unknown,
  unavailable,
  free,
  premium,
  expired,
  error,
}

/// Extension for SubscriptionStatus
extension SubscriptionStatusExtension on SubscriptionStatus {
  bool get isPremium => this == SubscriptionStatus.premium;

  bool get isFree =>
      this == SubscriptionStatus.free || this == SubscriptionStatus.expired;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.premium:
        return 'Premium';
      case SubscriptionStatus.free:
        return 'Free';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.unavailable:
        return 'Unavailable';
      case SubscriptionStatus.error:
        return 'Error';
      default:
        return 'Unknown';
    }
  }
}
