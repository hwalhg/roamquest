import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../models/subscription.dart';
import '../services/auth_service.dart';
import '../services/subscription_notification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

/// Timeout for waiting on StoreKit purchase stream after buyNonConsumable.
/// If no purchase update arrives within this window, reset the purchasing flag
/// so the user is not permanently stuck.
const Duration _purchaseTimeout = Duration(seconds: 30);

/// Repository for managing subscriptions
class SubscriptionRepository {
  factory SubscriptionRepository() => _instance;

  SubscriptionRepository._internal();

  static final SubscriptionRepository _instance =
      SubscriptionRepository._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Set<String> _processingTransactionIds = <String>{};
  Timer? _purchaseTimeoutTimer;

  // Subscription state
  final ValueNotifier<SubscriptionStatus> status = ValueNotifier(
    SubscriptionStatus.unknown,
  );

  final ValueNotifier<List<ProductDetails>> products = ValueNotifier([]);
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  bool _isInitialized = false;
  bool _isPurchasing = false;

  bool get _isSupabaseReady {
    try {
      SupabaseConfig.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  String? get _currentUserId {
    if (!_isSupabaseReady) return null;
    try {
      return AuthService().currentUserId;
    } catch (e) {
      AppLogger.warning(
          'Unable to read current user for subscription sync: $e');
      return null;
    }
  }

  /// Allow re-initialization for retry
  void resetForRetry() {
    _isInitialized = false;
    status.value = SubscriptionStatus.unknown;
    lastError.value = null;
  }

  /// Initialize subscription service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      AppLogger.info('Initializing subscription service...');
      _clearError();

      // Check if in-app purchase is available
      final isAvailable = await _iap.isAvailable();
      AppLogger.info('IAP Available: $isAvailable');

      if (!isAvailable) {
        AppLogger.warning('In-app purchase not available');
        _setError('In-app purchases are not available on this device.');
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

      AppLogger.info(
          'Subscription service initialized. Status: ${status.value}');
    } catch (e) {
      // Web platform or other error - in-app purchase not available
      AppLogger.warning('In-app purchase not available on this platform: $e');
      _setError('In-app purchases are not available on this platform.');
      status.value = SubscriptionStatus.unavailable;
    }
  }

  /// Load available products
  Future<void> loadProducts() async {
    try {
      _clearError();
      AppLogger.info('Loading products: ${SubscriptionProducts.allIds}');
      AppLogger.info('Querying App Store for product details...');

      final response = await _iap.queryProductDetails(
        SubscriptionProducts.allIds.toSet(),
      );

      AppLogger.info('Query response received');
      AppLogger.info(
          '  - Product details found: ${response.productDetails.length}');
      AppLogger.info('  - Not found IDs: ${response.notFoundIDs}');
      AppLogger.info('  - Error: ${response.error?.message ?? "None"}');

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('Products not found: ${response.notFoundIDs}');
        AppLogger.warning(
            'Please check App Store Connect to ensure these products exist');
      }

      if (response.productDetails.isEmpty) {
        _setError(_describeProductLoadFailure(response.error?.message));
        AppLogger.error(
            'No products found. Error: ${response.error?.message ?? "Unknown"}');
        AppLogger.error('This usually means:');
        AppLogger.error('  1. Products not configured in App Store Connect');
        AppLogger.error(
            '  2. Bundle ID mismatch between app and App Store Connect');
        AppLogger.error('  3. Not signed in to App Store on device');
        AppLogger.error(
            '  4. Products not yet approved (may take 15-30 minutes after creation)');
        status.value = SubscriptionStatus.error;
      } else {
        products.value = response.productDetails.toList();
        // Reset status from error to unknown so checkSubscriptionStatus can set correct state
        if (status.value == SubscriptionStatus.error) {
          status.value = SubscriptionStatus.unknown;
        }
        AppLogger.info('Loaded ${products.value.length} products:');
        for (final p in products.value) {
          AppLogger.info('  - ${p.id}: ${p.title} (${p.price})');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load products',
          error: e, stackTrace: stackTrace);
      if (e.toString().contains('No active account')) {
        AppLogger.warning(
            'No active App Store account. Please sign in to App Store in Settings');
        _setError(
          'No active App Store account. Please sign in to the App Store in Settings and try again.',
        );
      } else {
        _setError('Unable to load subscription products. Please try again.');
      }
      status.value = SubscriptionStatus.error;
    }
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    AppLogger.info('Purchase update received: ${purchases.length} purchases');
    for (final purchase in purchases) {
      AppLogger.info(
          '  - Product: ${purchase.productID}, Status: ${purchase.status}, Error: ${purchase.error?.message ?? "None"}');
      await _handlePurchase(purchase);
    }
    // Reset purchasing flag after all purchases are processed
    _isPurchasing = false;
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final transactionId = purchase.purchaseID;
    if (transactionId != null &&
        transactionId.isNotEmpty &&
        !_processingTransactionIds.add(transactionId)) {
      AppLogger.warning(
        'Skipping duplicate purchase update for transaction: $transactionId',
      );
      return;
    }

    try {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _clearError();
        final verifiedSubscription = await _verifyPurchase(purchase);

        await _saveSubscription(verifiedSubscription);

        if (verifiedSubscription.isExpired) {
          _setError(
            'The App Store returned an expired subscription for this account. If you are testing in Sandbox, use a fresh Sandbox Apple ID or wait for the subscription to renew before trying again.',
          );
          status.value = SubscriptionStatus.expired;
        } else {
          status.value = SubscriptionStatus.premium;
        }
        AppLogger.info('Purchase successful: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        AppLogger.error('Purchase error: ${purchase.error}');
        _setError(_describePurchaseError(purchase.error));
        status.value = SubscriptionStatus.error;
      } else if (purchase.status == PurchaseStatus.canceled) {
        _setError('Purchase was cancelled.');
        status.value = SubscriptionStatus.free;
      }
    } catch (e) {
      AppLogger.error('Error handling purchase', error: e);
      _setError(_sanitizeErrorMessage(e));
      status.value = SubscriptionStatus.error;
    } finally {
      if (transactionId != null && transactionId.isNotEmpty) {
        _processingTransactionIds.remove(transactionId);
      }

      // Complete the StoreKit transaction even if server-side verification
      // fails; otherwise iOS will keep replaying the same restored purchase.
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          AppLogger.error('Failed to complete purchase', error: e);
        }
      }
    }
  }

  /// Verify purchase with App Store Server API through the backend.
  Future<Subscription> _verifyPurchase(PurchaseDetails purchase) async {
    AppLogger.info('Verifying purchase with server: ${purchase.productID}');

    final transactionId = purchase.purchaseID;
    if (transactionId == null || transactionId.isEmpty) {
      throw Exception('Purchase is missing transaction ID');
    }

    final appReceipt = purchase.verificationData.serverVerificationData;

    return _verifySubscriptionWithServer(
      transactionId: transactionId,
      productId: purchase.productID,
      appReceipt: appReceipt.isEmpty ? null : appReceipt,
    );
  }

  Future<Subscription> _verifySubscriptionWithServer({
    required String transactionId,
    String? productId,
    String? appReceipt,
  }) async {
    if (!_isSupabaseReady) {
      throw Exception(
          'Supabase must be initialized before subscription verification');
    }

    final response = await SupabaseConfig.client.functions.invoke(
      ApiConstants.fnVerifyAppStoreSubscription,
      body: {
        'transactionId': transactionId,
        if (productId != null) 'productId': productId,
        if (appReceipt != null) 'appReceipt': appReceipt,
      },
    );

    AppLogger.info(
      'Subscription verification response received: status=${response.status}',
    );
    AppLogger.info('Subscription verification payload: ${response.data}');

    final payload = response.data;
    if (payload is! Map) {
      throw Exception('Verification response is not a JSON object');
    }

    final verified = payload['verified'] == true;
    final subscriptionJson = payload['subscription'];
    if (!verified || subscriptionJson is! Map) {
      final errorMessage = payload['error'] ??
          payload['message'] ??
          'Subscription verification failed';
      throw Exception(errorMessage);
    }

    return Subscription.fromJson(
      Map<String, dynamic>.from(subscriptionJson),
    );
  }

  Future<Subscription?> _refreshSubscriptionFromServer(
    Subscription subscription,
  ) async {
    final transactionId = subscription.originalTransactionId;
    if (transactionId == null || transactionId.isEmpty || !_isSupabaseReady) {
      return null;
    }

    try {
      return await _verifySubscriptionWithServer(
        transactionId: transactionId,
        productId: subscription.productId,
      );
    } catch (e) {
      AppLogger.warning('Failed to refresh subscription from server: $e');
      return null;
    }
  }

  /// Save subscription locally and sync it to the backend when possible.
  Future<void> _saveSubscription(Subscription subscription) async {
    try {
      await _saveSubscriptionLocally(subscription);
      await _saveSubscriptionToRemote(subscription);

      AppLogger.info(
        'Subscription saved: ${subscription.productId} (expires: ${subscription.endDate})',
      );

      // Schedule expiry notification
      await SubscriptionNotificationService().onSubscriptionChanged(
        isActive: true,
        endDate: subscription.endDate!,
      );
    } catch (e) {
      AppLogger.error('Failed to save subscription', error: e);
    }
  }

  Future<void> _saveSubscriptionLocally(Subscription subscription) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_product_id', subscription.productId);
    await prefs.setString(
      'subscription_transaction_id',
      subscription.originalTransactionId ?? '',
    );
    await prefs.setString(
      'subscription_start_date',
      subscription.startDate.toIso8601String(),
    );
    await prefs.setString(
      'subscription_end_date',
      subscription.endDate?.toIso8601String() ?? '',
    );
    await prefs.setBool('subscription_is_active', subscription.isActive);
    await prefs.setString(
      'subscription_latest_transaction_id',
      subscription.latestTransactionId ?? '',
    );
    await prefs.setString(
      'subscription_app_store_environment',
      subscription.appStoreEnvironment ?? '',
    );
    await prefs.setInt(
        'subscription_status_code', subscription.statusCode ?? 0);
    await prefs.setString(
      'subscription_verification_source',
      subscription.verificationSource ?? '',
    );
    await prefs.setString(
      'subscription_verified_at',
      subscription.verifiedAt?.toIso8601String() ?? '',
    );
  }

  Future<void> _saveSubscriptionToRemote(Subscription subscription) async {
    final userId = _currentUserId;
    if (userId == null) {
      AppLogger.warning(
        'Skipping remote subscription sync: no authenticated user',
      );
      return;
    }

    try {
      final client = SupabaseConfig.client;
      final existing = await _loadRemoteSubscription();
      final remoteSubscription = subscription.copyWith(
        id: existing?.id ?? subscription.id,
        userId: userId,
      );

      await client.from('subscriptions').upsert({
        ...remoteSubscription.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Subscription synced to remote for user $userId');
    } catch (e) {
      AppLogger.error('Failed to sync subscription to remote', error: e);
    }
  }

  Future<Subscription?> _loadRemoteSubscription() async {
    if (!_isSupabaseReady) return null;

    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final response = await SupabaseConfig.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Subscription.fromJson(response.first);
    } catch (e) {
      AppLogger.error('Failed to load remote subscription', error: e);
      return null;
    }
  }

  Future<void> _deactivateRemoteSubscriptions() async {
    if (!_isSupabaseReady) return;

    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await SupabaseConfig.client
          .from('subscriptions')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_active', true);
    } catch (e) {
      AppLogger.error('Failed to deactivate remote subscriptions', error: e);
    }
  }

  /// Check subscription status from remote first, then local storage.
  Future<void> checkSubscriptionStatus() async {
    // Don't override error status from loadProducts()
    if (status.value == SubscriptionStatus.error) {
      return;
    }

    try {
      final currentSubscription = await getSubscription();
      if (currentSubscription == null || !currentSubscription.isActive) {
        status.value = SubscriptionStatus.free;
        return;
      }

      final refreshedSubscription =
          await _refreshSubscriptionFromServer(currentSubscription);
      final effectiveSubscription =
          refreshedSubscription ?? currentSubscription;

      if (refreshedSubscription != null) {
        await _saveSubscriptionLocally(effectiveSubscription);
        await _saveSubscriptionToRemote(effectiveSubscription);
      }

      if (effectiveSubscription.isExpired || !effectiveSubscription.isActive) {
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
    if (_isPurchasing) {
      AppLogger.warning(
          'Purchase already in progress, ignoring duplicate call');
      _setError('A purchase is already in progress.');
      return false;
    }

    try {
      _clearError();
      status.value = SubscriptionStatus.unknown;
      AppLogger.info('purchaseSubscription called: $productId');
      final productDetails = products.value;
      final product = productDetails.firstWhere(
        (p) => p.id == productId,
      );

      _isPurchasing = true;
      final purchaseParam = PurchaseParam(productDetails: product);
      // Use buyNonConsumable for auto-renewable subscriptions on iOS
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      AppLogger.info('buyNonConsumable result: $result');

      if (!result) {
        _isPurchasing = false;
      } else {
        // Start a timeout timer – if StoreKit never fires a purchase update
        // (e.g. the user dismissed the sheet without confirming or cancelling
        // through the normal path), auto-reset so the user isn't stuck.
        _purchaseTimeoutTimer?.cancel();
        _purchaseTimeoutTimer = Timer(_purchaseTimeout, () {
          if (_isPurchasing) {
            AppLogger.warning(
                'Purchase timed out with no StoreKit response, resetting flag');
            _isPurchasing = false;
          }
        });
      }

      return result;
    } catch (e) {
      _isPurchasing = false;
      AppLogger.error('Failed to purchase', error: e);
      _setError(_sanitizeErrorMessage(e));
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      _clearError();
      await _iap.restorePurchases();
      AppLogger.info('Restoring purchases');
    } catch (e) {
      AppLogger.error('Failed to restore', error: e);
      _setError(_sanitizeErrorMessage(e));
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
      await prefs.remove('subscription_latest_transaction_id');
      await prefs.remove('subscription_app_store_environment');
      await prefs.remove('subscription_status_code');
      await prefs.remove('subscription_verification_source');
      await prefs.remove('subscription_verified_at');
      await _deactivateRemoteSubscriptions();

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
      final remoteSubscription = await _loadRemoteSubscription();
      if (remoteSubscription != null) {
        await _saveSubscriptionLocally(remoteSubscription);
        return remoteSubscription;
      }

      final prefs = await SharedPreferences.getInstance();
      final productId = prefs.getString('subscription_product_id');
      final transactionId = prefs.getString('subscription_transaction_id');
      final startDateStr = prefs.getString('subscription_start_date');
      final endDateStr = prefs.getString('subscription_end_date');
      final isActive = prefs.getBool('subscription_is_active') ?? false;
      final latestTransactionId =
          prefs.getString('subscription_latest_transaction_id');
      final appStoreEnvironment =
          prefs.getString('subscription_app_store_environment');
      final statusCode = prefs.getInt('subscription_status_code');
      final verificationSource =
          prefs.getString('subscription_verification_source');
      final verifiedAtStr = prefs.getString('subscription_verified_at');

      if (productId == null || startDateStr == null) {
        return null;
      }

      return Subscription(
        id: _uuid.v4(),
        userId: _currentUserId ?? 'user',
        productId: productId,
        startDate: DateTime.parse(startDateStr),
        endDate: (endDateStr != null && endDateStr.isNotEmpty)
            ? DateTime.parse(endDateStr)
            : null,
        isActive: isActive,
        autoRenew: true, // Default to true for iOS
        originalTransactionId: transactionId,
        latestTransactionId:
            latestTransactionId?.isEmpty == true ? null : latestTransactionId,
        appStoreEnvironment:
            appStoreEnvironment?.isEmpty == true ? null : appStoreEnvironment,
        statusCode: statusCode == 0 ? null : statusCode,
        verificationSource: verificationSource?.isEmpty == true
            ? 'legacy_local'
            : verificationSource,
        verifiedAt: (verifiedAtStr != null && verifiedAtStr.isNotEmpty)
            ? DateTime.parse(verifiedAtStr)
            : null,
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
    _setError(_sanitizeErrorMessage(error));
    status.value = SubscriptionStatus.error;
  }

  /// Dispose
  void dispose() {
    // Shared singleton for the whole app lifecycle.
    // Individual pages should remove their own listeners, but the repository
    // keeps the purchase stream alive to avoid duplicate StoreKit listeners.
  }

  void _clearError() {
    lastError.value = null;
  }

  void _setError(String message) {
    lastError.value = message;
  }

  String _describeProductLoadFailure(String? storeMessage) {
    if (storeMessage != null && storeMessage.trim().isNotEmpty) {
      return _sanitizeErrorMessage(storeMessage);
    }

    return 'No subscription products were returned from the App Store. Check App Store Connect product setup and your signed-in App Store account.';
  }

  String _describePurchaseError(IAPError? error) {
    final message = error?.message;
    if (message != null && message.trim().isNotEmpty) {
      return _sanitizeErrorMessage(message);
    }

    return 'The App Store could not complete the purchase.';
  }

  String _sanitizeErrorMessage(Object? error) {
    final raw = error?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return 'Unable to complete purchase. Please try again.';
    }

    var message = raw.replaceFirst('Exception:', '').trim();
    if (message.startsWith('error:')) {
      message = message.substring(6).trim();
    }

    return message;
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
