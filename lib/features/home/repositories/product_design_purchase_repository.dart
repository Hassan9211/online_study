import '../models/product_design_purchase_record.dart';

abstract interface class ProductDesignPurchaseRepository {
  Future<ProductDesignPurchaseRecord> loadPurchase();
  Future<void> savePurchase(ProductDesignPurchaseRecord record);
}
