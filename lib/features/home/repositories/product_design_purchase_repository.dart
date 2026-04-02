import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import '../models/product_design_purchase_record.dart';

abstract interface class ProductDesignPurchaseRepository {
  Future<ProductDesignPurchaseRecord> loadCachedPurchase();
  Future<ProductDesignPurchaseRecord> loadPurchase();
  Future<void> savePurchase(ProductDesignPurchaseRecord record);
  Future<void> clearCachedState();
  Future<List<PaymentMethodRecord>> loadPaymentMethods();
  Future<String> createCheckout({
    required PaymentCheckoutRequest request,
  });
  Future<ProductDesignPurchaseRecord> verifyPin({
    required String paymentId,
    required String pin,
  });
}
