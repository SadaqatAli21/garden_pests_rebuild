import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class StoreKeys {
  // Android specific keys (as provided by user)
  static const String weeklyAndroid = 'weekly_sub';
  static const String monthlyAndroid = 'monthy_sub';
  static const String yearlyAndroid = 'yearly_sub';
  static const String lifetimeProAndroid = 'lifetime_pro_android';

  // iOS specific keys (as provided by user)
  static const String weeklyIOS = 'weekly_sub_ios_pests';
  static const String monthlyIOS = 'monthy_sub_ios_pests';
  static const String yearlyIOS = 'yearly_sub_ios_pests';
  static const String lifetimeProIOS = 'lifetime_pro_ios_pests';

  // mac specific keys (as provided by user)
  static const String weeklyMac = 'weekly_sub_ios_pests';
  static const String monthlyMac = 'monthy_sub_ios_pests';
  static const String yearlyMac = 'yearly_sub_ios_pests';
  static const String lifetimeProMac = 'lifetime_pro_ios_pests';

  static List<String> getSubscriptionIds() {
    if (Platform.isIOS) {
      return [weeklyIOS, monthlyIOS, yearlyIOS, lifetimeProIOS];
    } else if (Platform.isAndroid) {
      return [weeklyAndroid, monthlyAndroid, yearlyAndroid, lifetimeProAndroid];
    } else if (Platform.isMacOS) {
      return [weeklyMac, monthlyMac, yearlyMac, lifetimeProMac];
    }
    return [];
  }

  static String getLifetimeKey() {
    if (Platform.isIOS) return lifetimeProIOS;
    if (Platform.isMacOS) return lifetimeProMac;
    return lifetimeProAndroid;
  }

  static String getMonthlyKey() {
    if (Platform.isIOS) return monthlyIOS;
    if (Platform.isMacOS) return monthlyMac;
    return monthlyAndroid;
  }

  static String getYearlyKey() {
    if (Platform.isIOS) return yearlyIOS;
    if (Platform.isMacOS) return yearlyMac;
    return yearlyAndroid;
  }

  static String getWeeklyKey() {
    if (Platform.isIOS) return weeklyIOS;
    if (Platform.isMacOS) return weeklyMac;
    return weeklyAndroid;
  }
}

final inAppPurchaseProvider = ChangeNotifierProvider<InAppPurchaseProvider>((
    ref,
    ) {
  return InAppPurchaseProvider();
});

class InAppPurchaseProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<PurchaseDetails> _purchaseUpdateController =
  StreamController<PurchaseDetails>.broadcast();

  Stream<PurchaseDetails> get purchaseUpdates =>
      _purchaseUpdateController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPremium = true; // [DEBUG] Forced true for testing
  bool get isPremium => _isPremium;

  // Constants
  static const String _premiumStatusKey = 'is_premium_user';
  static const String _purchasedProductIdKey = 'purchased_product_id';
  static const String _purchaseDateKey = 'purchase_date';

  bool _isInitialized = false;

  InAppPurchaseProvider() {
    _initOnLaunch();
  }

  void _initOnLaunch() async {
    await init();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      _isPremium = true; // [DEBUG] Always true for testing

      // Listen to purchase stream
      _subscription = _iap.purchaseStream.listen(
        _handlePurchase,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint("Error in purchase stream: $error");
        },
      );

      // Load products
      await _loadProducts();

      // Check for pending purchases
      if (Platform.isAndroid) {
        try {
          await _iap.restorePurchases();
        } catch (e) {
          debugPrint("Restore purchases failed: $e");
        }
      }
    } catch (e) {
      debugPrint("Error initializing IAP Provider: $e");
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> _loadProducts() async {
    final List<String> subscriptionIds = StoreKeys.getSubscriptionIds();
    debugPrint("Querying products with IDs: $subscriptionIds");

    final Set<String> ids = Set.from(subscriptionIds);
    if (ids.isEmpty) {
      debugPrint("No product IDs to query.");
      return;
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.error != null) {
      debugPrint("Error querying products: ${response.error}");
    }

    debugPrint("Products found: ${response.productDetails.length}");
    for (var product in response.productDetails) {
      debugPrint("Found product: ${product.id} - ${product.price}");
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products NOT found: ${response.notFoundIDs}");
    }

    _products = response.productDetails;
    notifyListeners();
  }

  // -----------------------------------------------------------------------------
  // Public API: Get Price
  // -----------------------------------------------------------------------------
  String? getPrice(String productId) {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (e) {
      return null;
    }
  }

  // -----------------------------------------------------------------------------
  // Public API: Purchase
  // -----------------------------------------------------------------------------
  Future<void> purchase(String productId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final product = _products.firstWhere(
            (p) => p.id == productId,
        orElse: () => throw Exception("Product not found"),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // All Pro features (subs/lifetime) are non-consumable.
      // Removed the buyConsumable debug branch to allow store persistence.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (e is PlatformException) {
        debugPrint("Purchase failed with PlatformException:");
        debugPrint("  Code: ${e.code}");
        debugPrint("  Message: ${e.message}");
        debugPrint("  Details: ${e.details}");
      } else {
        debugPrint("Purchase failed: $e");
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------------
  // Restore & Validation
  // -----------------------------------------------------------------------------

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // Increased wait to allow the purchaseStream to process any restored items
      await Future.delayed(const Duration(milliseconds: 2500));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _isPremium;
  }

  void _handlePurchase(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      _purchaseUpdateController.add(purchase);
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndSavePurchase(purchase);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _isLoading = false;
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint("Purchase Error: ${purchase.error}");
        _isLoading = false;
      } else if (purchase.status == PurchaseStatus.canceled) {
        _isLoading = false;
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndSavePurchase(PurchaseDetails purchase) async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumStatusKey, true);
    await prefs.setString(_purchasedProductIdKey, purchase.productID);
    await prefs.setString(_purchaseDateKey, DateTime.now().toIso8601String());
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseUpdateController.close();
    super.dispose();
  }
}
