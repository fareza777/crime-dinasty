import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// One-time Remove Ads. Product id: `com.vicedynasty.life.remove_ads`
///
/// Play Billing: create a managed product with that id. The store query is
/// attempted; if the catalog is empty (sideload / test APK), Settings exposes
/// a documented debug grant so the rest of the economy can be QA'd.
class IapService {
  static const productId = 'com.vicedynasty.life.remove_ads';

  bool available = false;
  ProductDetails? product;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      available = await InAppPurchase.instance.isAvailable().timeout(
        const Duration(seconds: 6),
        onTimeout: () => false,
      );
      if (!available) return;
      final resp = await InAppPurchase.instance.queryProductDetails({productId}).timeout(
        const Duration(seconds: 8),
      );
      if (resp.productDetails.isNotEmpty) {
        product = resp.productDetails.first;
      }
    } catch (e) {
      debugPrint('IAP init skipped: $e');
      available = false;
    }
  }

  Future<bool> buy() async {
    final p = product;
    if (p == null) return false;
    try {
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: p),
      );
      return ok;
    } catch (e) {
      debugPrint('IAP buy skipped: $e');
      return false;
    }
  }
}
