import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';

/// Mock for InAppPurchase
class MockInAppPurchase extends Mock implements InAppPurchase {}

/// Mock for PurchaseDetails
class MockPurchaseDetails extends Mock implements PurchaseDetails {}

/// Mock for ProductDetails
class MockProductDetails extends Mock implements ProductDetails {}

/// Helper class for creating mock IAP products
class MockIAPHelper {
  /// Create a mock monthly product
  static MockProductDetails createMonthlyProduct() {
    final product = MockProductDetails();
    when(product.id).thenReturn('com.roamquest.subscription.monthly');
    when(product.title).thenReturn('Monthly Premium');
    when(product.description).thenReturn('1 month subscription');
    when(product.price).thenReturn('\$4.99');
    when(product.rawPrice).thenReturn(4.99);
    when(product.currencyCode).thenReturn('USD');
    return product;
  }

  /// Create a mock quarterly product
  static MockProductDetails createQuarterlyProduct() {
    final product = MockProductDetails();
    when(product.id).thenReturn('com.roamquest.subscription.quarterly');
    when(product.title).thenReturn('Quarterly Premium');
    when(product.description).thenReturn('3 month subscription');
    when(product.price).thenReturn('\$13.49');
    when(product.rawPrice).thenReturn(13.49);
    when(product.currencyCode).thenReturn('USD');
    return product;
  }

  /// Create a mock yearly product
  static MockProductDetails createYearlyProduct() {
    final product = MockProductDetails();
    when(product.id).thenReturn('com.roamquest.subscription.yearly');
    when(product.title).thenReturn('Yearly Premium');
    when(product.description).thenReturn('1 year subscription');
    when(product.price).thenReturn('\$47.99');
    when(product.rawPrice).thenReturn(47.99);
    when(product.currencyCode).thenReturn('USD');
    return product;
  }

  /// Get all mock products
  static List<MockProductDetails> createAllProducts() {
    return [
      createMonthlyProduct(),
      createQuarterlyProduct(),
      createYearlyProduct(),
    ];
  }

  /// Create a successful purchase details
  static MockPurchaseDetails createSuccessfulPurchase({
    required String productID,
    String? transactionDate,
  }) {
    final purchaseDetails = MockPurchaseDetails();
    when(purchaseDetails.productID).thenReturn(productID);
    when(purchaseDetails.status).thenReturn(PurchaseStatus.purchased);
    when(purchaseDetails.transactionDate).thenReturn(
      transactionDate ?? DateTime.now().toIso8601String(),
    );
    when(purchaseDetails.purchaseID).thenReturn('test_transaction_id');
    when(purchaseDetails.verificationData).thenReturn(
      PurchaseVerificationData(
        serverVerificationData: 'test_verification_data',
        localVerificationData: 'test_local_data',
        source: IAPSource.appStore,
      ),
    );
    when(purchaseDetails.billingClientPurchase).thenReturn(null);
    when(purchaseDetails.pendingCompletePurchase).thenReturn(null);
    return purchaseDetails;
  }

  /// Create a pending purchase details
  static MockPurchaseDetails createPendingPurchase({
    required String productID,
  }) {
    final purchaseDetails = MockPurchaseDetails();
    when(purchaseDetails.productID).thenReturn(productID);
    when(purchaseDetails.status).thenReturn(PurchaseStatus.pending);
    when(purchaseDetails.transactionDate).thenReturn(null);
    when(purchaseDetails.purchaseID).thenReturn(null);
    when(purchaseDetails.verificationData).thenReturn(null);
    when(purchaseDetails.billingClientPurchase).thenReturn(null);
    when(purchaseDetails.pendingCompletePurchase).thenReturn(null);
    return purchaseDetails;
  }

  /// Create a failed purchase details
  static MockPurchaseDetails createFailedPurchase({
    required String productID,
    String? error,
  }) {
    final purchaseDetails = MockPurchaseDetails();
    when(purchaseDetails.productID).thenReturn(productID);
    when(purchaseDetails.status).thenReturn(PurchaseStatus.error);
    when(purchaseDetails.transactionDate).thenReturn(null);
    when(purchaseDetails.purchaseID).thenReturn(null);
    when(purchaseDetails.verificationData).thenReturn(null);
    when(purchaseDetails.billingClientPurchase).thenReturn(null);
    when(purchaseDetails.pendingCompletePurchase).thenReturn(null);
    when(purchaseDetails.error).thenReturn(error ?? 'Purchase failed');
    return purchaseDetails;
  }

  /// Create a cancelled purchase details
  static MockPurchaseDetails createCancelledPurchase({
    required String productID,
  }) {
    final purchaseDetails = MockPurchaseDetails();
    when(purchaseDetails.productID).thenReturn(productID);
    when(purchaseDetails.status).thenReturn(PurchaseStatus.canceled);
    when(purchaseDetails.transactionDate).thenReturn(null);
    when(purchaseDetails.purchaseID).thenReturn(null);
    when(purchaseDetails.verificationData).thenReturn(null);
    when(purchaseDetails.billingClientPurchase).thenReturn(null);
    when(purchaseDetails.pendingCompletePurchase).thenReturn(null);
    return purchaseDetails;
  }
}

/// Mock for InAppPurchaseConnection helper
class MockInAppPurchaseConnection {
  /// Create a mock connection with available IAP
  static MockInAppPurchase createAvailable() {
    final mock = MockInAppPurchase();
    when(mock.isAvailable()).thenAnswer((_) => true);
    return mock;
  }

  /// Create a mock connection with unavailable IAP
  static MockInAppPurchase createUnavailable() {
    final mock = MockInAppPurchase();
    when(mock.isAvailable()).thenAnswer((_) => false);
    return mock;
  }

  /// Setup mock to return products
  static void setupProducts(
    MockInAppPurchase mock,
    List<MockProductDetails> products,
  ) {
    when(mock.queryProductDetails(any)).thenAnswer((_) async => products);
  }
}

/// Mock for SharedPreferences
class MockSharedPreferences extends Mock {}
