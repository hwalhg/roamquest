import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/city.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';

/// Repository for managing per-city permanent unlock subscriptions
class CitySubscriptionRepository {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final SupabaseClient _client = SupabaseConfig.client;

  // Purchase state
  final ValueNotifier<bool> isPurchasing = ValueNotifier(false);
  final ValueNotifier<ProductDetails?> cityProduct = ValueNotifier(null);

  /// Initialize subscription service for a specific city
  Future<void> initializeForCity(City city) async {
    try {
      // Check if in-app purchase is available
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        AppLogger.warning('In-app purchase not available');
        return;
      }

      // Listen to purchase updates
      final purchaseStream = _iap.purchaseStream;
      _subscription = purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );

      // Load city product
      await _loadCityProduct(city);
    } catch (e) {
      AppLogger.warning('In-app purchase not available on this platform: $e');
    }
  }

  /// Load product for a specific city
  Future<void> _loadCityProduct(City city) async {
    try {
      final productId = SubscriptionProducts.getCityProductId(city.name);

      final response = await _iap.queryProductDetails({productId});

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('City product not found: ${response.notFoundIDs}');
        // Product not found in App Store, create a mock product for UI
        cityProduct.value = _createMockProduct(city);
      } else if (response.productDetails.isEmpty) {
        AppLogger.warning('No products found for city: ${city.name}');
        cityProduct.value = _createMockProduct(city);
      } else {
        cityProduct.value = response.productDetails.first;
        AppLogger.info('Loaded product for ${city.name}: ${cityProduct.value?.id}');
      }
    } catch (e) {
      AppLogger.error('Failed to load city product', error: e);
      cityProduct.value = _createMockProduct(city);
    }
  }

  /// Create a mock product for UI when IAP is not available
  ProductDetails _createMockProduct(City city) {
    return ProductDetails(
      id: SubscriptionProducts.getCityProductId(city.name),
      title: 'Unlock ${city.name}',
      description: 'Permanent access to all ${city.name} experiences',
      price: '\$${city.subscriptionPrice.toStringAsFixed(2)}',
      rawPrice: city.subscriptionPrice,
      currencyCode: 'USD',
    );
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Extract city name from product ID
        final cityName = _extractCityNameFromProductId(purchase.productID);
        if (cityName != null) {
          await _unlockCityInDatabase(cityName);
        }

        AppLogger.info('Purchase successful: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        AppLogger.error('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        AppLogger.info('Purchase canceled');
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } catch (e) {
      AppLogger.error('Error handling purchase', error: e);
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Extract city name from product ID
  String? _extractCityNameFromProductId(String productId) {
    if (productId.startsWith('com.roamquest.city.')) {
      final cityNamePart = productId.substring('com.roamquest.city.'.length);
      // Convert back from sanitized format
      return cityNamePart.replaceAll('_', ' ');
    }
    return null;
  }

  /// Unlock city in database after successful purchase
  Future<void> _unlockCityInDatabase(String cityName) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.error('User not authenticated');
      return;
    }

    try {
      // Check if already unlocked
      final existing = await _client
          .from('user_cities')
          .select()
          .eq('user_id', userId)
          .eq('city_name', cityName)
          .maybeSingle();

      if (existing == null) {
        // Add unlock record
        await _client.from('user_cities').insert({
          'user_id': userId,
          'city_name': cityName,
          'unlocked_at': DateTime.now().toIso8601String(),
          'is_permanent': true,
        });
        AppLogger.info('Unlocked city in database: $cityName');
      }
    } catch (e) {
      AppLogger.error('Failed to unlock city in database', error: e);
    }
  }

  /// Purchase permanent unlock for a city
  Future<bool> purchaseCityUnlock(City city) async {
    if (isPurchasing.value) return false;

    isPurchasing.value = true;

    try {
      // For free cities or when IAP is not available (web), just unlock directly
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable || city.isFree) {
        await _unlockCityInDatabase(city.name);
        isPurchasing.value = false;
        return true;
      }

      // Load or get the product
      if (cityProduct.value == null ||
          cityProduct.value!.id != SubscriptionProducts.getCityProductId(city.name)) {
        await _loadCityProduct(city);
      }

      if (cityProduct.value == null) {
        isPurchasing.value = false;
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: cityProduct.value!);
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      // The actual unlock will happen in _handlePurchase when purchase completes
      return result;
    } catch (e) {
      AppLogger.error('Failed to purchase city unlock', error: e);
      isPurchasing.value = false;
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
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    AppLogger.error('Purchase stream error', error: error);
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
    isPurchasing.dispose();
    cityProduct.dispose();
  }
}
