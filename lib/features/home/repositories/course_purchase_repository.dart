import '../models/course_purchase_record.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';

abstract interface class CoursePurchaseRepository {
  Future<List<CoursePurchaseRecord>> loadCachedPurchases();
  Future<List<CoursePurchaseRecord>> loadPurchases();
  Future<void> savePurchase(CoursePurchaseRecord record);
  Future<void> clearCachedState();
  Future<List<PaymentMethodRecord>> loadPaymentMethods();
  Future<String> createCheckout({
    required String courseId,
    required PaymentCheckoutRequest request,
  });
  Future<CoursePurchaseRecord> verifyPin({
    required String courseId,
    required String courseTitle,
    required String paymentId,
    required String pin,
  });
}
