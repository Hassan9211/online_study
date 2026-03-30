import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/payment_method_record.dart';
import '../models/product_design_purchase_record.dart';
import 'local_product_design_purchase_repository.dart';
import 'product_design_purchase_repository.dart';

class RemoteProductDesignPurchaseRepository
    implements ProductDesignPurchaseRepository {
  RemoteProductDesignPurchaseRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalProductDesignPurchaseRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<ProductDesignPurchaseRecord> loadPurchase() async {
    final cachedRecord = await _localStore.loadPurchase();
    if (!await _hasAccessToken()) {
      return cachedRecord;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.myCourses);
      final remoteRecord = _parsePurchaseFromMyCourses(body);
      await _localStore.savePurchase(remoteRecord);
      return remoteRecord;
    } catch (_) {
      return cachedRecord;
    }
  }

  @override
  Future<void> savePurchase(ProductDesignPurchaseRecord record) {
    return _localStore.savePurchase(record);
  }

  @override
  Future<List<PaymentMethodRecord>> loadPaymentMethods() async {
    final cachedMethods = await _localStore.loadPaymentMethods();
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return cachedMethods;
      }
      throw const ApiException(
        'GET /payments/methods backend ko nahi bheji gayi kyun ke login token missing hai. Dobara login karein.',
      );
    }

    final body = await _apiClient.getJson(ApiEndpoints.payments.methods);
    final payload = unwrapBody(body, keys: const ['data', 'methods']);
    final list = payload is List
        ? payload
        : readList(asMap(body), const ['methods', 'data']);

    final methods = list.map((item) {
      final map = asMap(item);
      final id = readString(map, const ['id', 'method_id']);
      final label = readString(
        map,
        const ['label', 'name', 'brand', 'type'],
        fallback: 'Card',
      );
      final maskedNumber = _resolveMaskedNumber(map);

      return PaymentMethodRecord(
        id: id.isEmpty ? 'method_$label' : id,
        label: label,
        maskedNumber: maskedNumber,
      );
    }).toList();

    if (methods.isEmpty && ApiConfig.useMockPaymentMethods) {
      return cachedMethods;
    }

    return methods;
  }

  @override
  Future<String> createCheckout({required String paymentMethodId}) async {
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return _localStore.createCheckout(paymentMethodId: paymentMethodId);
      }
      throw const ApiException(
        'POST /payments/checkout backend ko nahi bheji gayi kyun ke login token missing hai. Dobara login karein.',
      );
    }

    final body = await _apiClient.postJson(
      ApiEndpoints.payments.checkout,
      body: <String, dynamic>{
        'course_id': ApiConfig.productDesignCourseId,
        'courseId': ApiConfig.productDesignCourseId,
        'payment_method_id': paymentMethodId,
        'paymentMethodId': paymentMethodId,
      },
    );

    final root = asMap(body);
    final data = asMap(unwrapBody(body, keys: const ['data', 'payment']));
    final paymentId = readString(
      data,
      const ['id', 'payment_id'],
      fallback: readString(root, const ['payment_id', 'id']),
    );

    if (paymentId.isEmpty) {
      throw const ApiException('Checkout completed but payment id missing.');
    }

    return paymentId;
  }

  @override
  Future<ProductDesignPurchaseRecord> verifyPin({
    required String paymentId,
    required String pin,
  }) async {
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return _localStore.verifyPin(paymentId: paymentId, pin: pin);
      }
      throw const ApiException(
        'POST /payments/verify-pin backend ko nahi bheji gayi kyun ke login token missing hai. Dobara login karein.',
      );
    }

    final body = await _apiClient.postJson(
      ApiEndpoints.payments.verifyPin,
      body: <String, dynamic>{
        'payment_id': paymentId,
        'paymentId': paymentId,
        'pin': pin,
      },
    );

    final parsedRecord = _parsePurchaseFromVerifyPin(body, paymentId: paymentId);
    await _localStore.savePurchase(parsedRecord);
    return parsedRecord;
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  ProductDesignPurchaseRecord _parsePurchaseFromMyCourses(dynamic body) {
    final payload = unwrapBody(body, keys: const ['data', 'courses', 'my_courses']);
    final list = payload is List
        ? payload
        : readList(asMap(body), const ['courses', 'my_courses', 'data']);

    for (final item in list) {
      final map = asMap(item);
      final courseId = readString(map, const ['id', 'course_id', 'slug']);
      final title = readString(map, const ['title', 'name']).toLowerCase();

      final isTargetCourse =
          courseId == ApiConfig.productDesignCourseId ||
          title.contains('product design');
      if (!isTargetCourse) {
        continue;
      }

      return ProductDesignPurchaseRecord(
        isPurchased: true,
        purchaseId: readString(
          map,
          const ['purchase_id', 'payment_id', 'enrollment_id', 'id'],
          fallback: courseId,
        ),
        purchasedAt: readDateTime(
          map,
          const ['purchased_at', 'enrolled_at', 'created_at'],
        ),
      );
    }

    return const ProductDesignPurchaseRecord.empty();
  }

  ProductDesignPurchaseRecord _parsePurchaseFromVerifyPin(
    dynamic body, {
    required String paymentId,
  }) {
    final root = asMap(body);
    final data = asMap(unwrapBody(body, keys: const ['data', 'payment']));
    final paidAt = readDateTime(
      data,
      const ['paid_at', 'completed_at', 'updated_at', 'created_at'],
    );

    final purchased = readBool(
      data,
      const ['success', 'completed', 'paid', 'is_paid'],
      fallback: true,
    );

    return ProductDesignPurchaseRecord(
      isPurchased: purchased,
      purchaseId: readString(
        data,
        const ['id', 'payment_id'],
        fallback: readString(root, const ['payment_id'], fallback: paymentId),
      ),
      purchasedAt: paidAt ?? DateTime.now(),
    );
  }

  String _resolveMaskedNumber(Map<String, dynamic> map) {
    final directMasked = readString(
      map,
      const ['masked_number', 'maskedNumber', 'card_mask', 'card_number'],
    );
    if (directMasked.isNotEmpty) {
      return directMasked;
    }

    final last4 = readString(
      map,
      const ['last4', 'last_four', 'card_last_four'],
    );
    if (last4.isNotEmpty) {
      return '**** **** **** $last4';
    }

    return '**** **** ****';
  }
}
