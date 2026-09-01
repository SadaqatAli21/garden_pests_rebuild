import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'in_app_purchase_provider.dart';

final subscriptionProvider = ChangeNotifierProvider<SubscriptionProvider>((
    ref,
    ) {
  final iapProvider = ref.watch(inAppPurchaseProvider);
  final provider = SubscriptionProvider();
  provider.updateFromIAP(iapProvider);
  return provider;
});

class SubscriptionProvider with ChangeNotifier {
  bool _isPremium = true; // [DEBUG] Forced to true for development
  static const String _premiumKey = 'is_premium_user';
  bool _disposed = false;
  SubscriptionProvider() {
    _loadSubscriptionStatus();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool get isPremium => _isPremium;

  // This will be called via ProxyProvider or manually updated
  void updateFromIAP(InAppPurchaseProvider iapProvider) {
    if (_isPremium != iapProvider.isPremium) {
      _isPremium = iapProvider.isPremium;
      _safeNotify();
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = true; // [DEBUG] Always true for testing
    _safeNotify();
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    _isPremium = value;
    _safeNotify();
  }

  // Toggle for testing/debug purposes
  Future<void> togglePremium() async {
    await setPremium(!_isPremium);
  }
}
