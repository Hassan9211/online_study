import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_design_purchase_record.dart';
import 'product_design_purchase_repository.dart';

class LocalProductDesignPurchaseRepository
    implements ProductDesignPurchaseRepository {
  static const String _isPurchasedKey = 'product_design_is_purchased';
  static const String _purchaseIdKey = 'product_design_purchase_id';
  static const String _purchasedAtKey = 'product_design_purchased_at';

  @override
  Future<ProductDesignPurchaseRecord> loadPurchase() async {
    final preferences = await SharedPreferences.getInstance();
    final purchasedAtRaw = preferences.getString(_purchasedAtKey);

    return ProductDesignPurchaseRecord(
      isPurchased: preferences.getBool(_isPurchasedKey) ?? false,
      purchaseId: preferences.getString(_purchaseIdKey) ?? '',
      purchasedAt: purchasedAtRaw == null
          ? null
          : DateTime.tryParse(purchasedAtRaw),
    );
  }

  @override
  Future<void> savePurchase(ProductDesignPurchaseRecord record) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_isPurchasedKey, record.isPurchased);
    await preferences.setString(_purchaseIdKey, record.purchaseId);

    if (record.purchasedAt == null) {
      await preferences.remove(_purchasedAtKey);
    } else {
      await preferences.setString(
        _purchasedAtKey,
        record.purchasedAt!.toIso8601String(),
      );
    }
  }
}
