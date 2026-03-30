import '../models/payment_method_record.dart';
import '../models/product_design_purchase_record.dart';

abstract interface class ProductDesignPurchaseRepository {
  Future<ProductDesignPurchaseRecord> loadPurchase();
  Future<void> savePurchase(ProductDesignPurchaseRecord record);
  Future<List<PaymentMethodRecord>> loadPaymentMethods();
  Future<String> createCheckout({required String paymentMethodId});
  Future<ProductDesignPurchaseRecord> verifyPin({
    required String paymentId,
    required String pin,
  });
}
