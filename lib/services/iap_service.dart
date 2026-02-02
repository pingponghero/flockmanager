import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Service for managing in-app purchases.
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  /// Product ID for the premium unlock.
  static const String premiumProductId = 'flock_manager_premium';

  /// Set of all product IDs.
  static const Set<String> _productIds = {premiumProductId};

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Callback for when purchase status changes.
  void Function(bool isPremium)? onPurchaseStatusChanged;

  /// Callback for purchase errors.
  void Function(String error)? onPurchaseError;

  bool _isAvailable = false;
  ProductDetails? _premiumProduct;

  /// Whether the store is available.
  bool get isAvailable => _isAvailable;

  /// The premium product details (price, title, etc.).
  ProductDetails? get premiumProduct => _premiumProduct;

  /// Initialize the IAP service.
  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) return;

      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          onPurchaseError?.call(error.toString());
        },
      );

      // Load products
      await _loadProducts();
    } catch (e) {
      // Don't let IAP failures crash the app
      _isAvailable = false;
    }
  }

  /// Load product details from the store.
  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    final response = await _iap.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      // Product not found in store - this is expected during development
      // In production, the product would be configured in App Store Connect / Play Console
    }

    if (response.productDetails.isNotEmpty) {
      // Find the premium product, or use the first product if not found
      final products = response.productDetails;
      final premium = products.where((p) => p.id == premiumProductId);
      _premiumProduct = premium.isNotEmpty ? premium.first : products.first;
    }
  }

  /// Handle purchase updates from the store.
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  /// Handle a single purchase.
  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.pending) {
      // Show loading or pending UI
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');
      _completePurchase(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Verify purchase if needed (server-side verification recommended for production)
      _verifyAndDeliverPurchase(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      _completePurchase(purchase);
      return;
    }
  }

  /// Verify and deliver the purchase.
  void _verifyAndDeliverPurchase(PurchaseDetails purchase) {
    // In a production app, you would verify the purchase with your server
    // For this app, we trust the store directly

    if (purchase.productID == premiumProductId) {
      onPurchaseStatusChanged?.call(true);
    }

    _completePurchase(purchase);
  }

  /// Complete the purchase transaction.
  void _completePurchase(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  /// Purchase the premium product.
  Future<bool> purchasePremium() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return false;
    }

    if (_premiumProduct == null) {
      onPurchaseError?.call('Product not available');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: _premiumProduct!);

    try {
      // On iOS, use buyNonConsumable for one-time purchases
      // On Android, both work but buyNonConsumable is cleaner
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      onPurchaseError?.call(e.toString());
    }
  }

  /// Get the price string for display.
  String get priceString {
    if (_premiumProduct != null) {
      return _premiumProduct!.price;
    }
    // Default fallback price
    return Platform.isIOS ? '\$4.99' : '\$4.99';
  }

  /// Dispose of resources.
  void dispose() {
    _subscription?.cancel();
  }
}
