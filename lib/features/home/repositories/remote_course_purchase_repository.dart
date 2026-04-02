import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/course_purchase_record.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import 'course_purchase_repository.dart';
import 'local_course_purchase_repository.dart';

class RemoteCoursePurchaseRepository implements CoursePurchaseRepository {
  RemoteCoursePurchaseRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalCoursePurchaseRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<List<CoursePurchaseRecord>> loadCachedPurchases() {
    return _localStore.loadPurchases();
  }

  @override
  Future<List<CoursePurchaseRecord>> loadPurchases() async {
    final cachedPurchases = await _localStore.loadPurchases();
    if (!await _hasAccessToken()) {
      return cachedPurchases;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.myCourses);
      final purchases = _parsePurchasesFromMyCourses(body);
      if (purchases.isNotEmpty) {
        await _localStore.savePurchases(purchases);
        return purchases;
      }
      return cachedPurchases;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return cachedPurchases;
    } catch (_) {
      return cachedPurchases;
    }
  }

  @override
  Future<void> savePurchase(CoursePurchaseRecord record) {
    return _localStore.savePurchase(record);
  }

  @override
  Future<void> clearCachedState() {
    return _localStore.clearCachedState();
  }

  @override
  Future<List<PaymentMethodRecord>> loadPaymentMethods() async {
    final cachedMethods = await _localStore.loadPaymentMethods();
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return cachedMethods;
      }
      throw const ApiException(
        'GET /payments/methods was not sent because the login token is missing. Please log in again.',
      );
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.payments.methods);
      final payload = unwrapBody(body);
      final list = payload is List
          ? payload
          : readList(asMap(payload), const ['methods', 'data']);

      final methods = list.map((item) {
        final map = asMap(item);
        final id = readString(map, const ['id']);
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

      if (methods.isNotEmpty) {
        await _localStore.savePaymentMethods(methods);
        return methods;
      }

      if (ApiConfig.useMockPaymentMethods || cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        throw const ApiException(
          'Your session has expired. Please log in again to load payment methods.',
          statusCode: 401,
        );
      }

      if (cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
      rethrow;
    } catch (_) {
      if (cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
      rethrow;
    }

    return cachedMethods;
  }

  @override
  Future<String> createCheckout({
    required String courseId,
    required PaymentCheckoutRequest request,
  }) async {
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return _localStore.createCheckout(courseId: courseId, request: request);
      }
      throw const ApiException(
        'POST /payments/checkout was not sent because the login token is missing. Please log in again.',
      );
    }

    final body = await _postCheckout(courseId: courseId, request: request);

    final payload = asMap(unwrapBody(body));
    final payment = readMap(payload, const ['payment']);
    final paymentId = readString(
      payment,
      const ['id'],
      fallback: readString(payload, const ['payment_id', 'id']),
    );

    if (paymentId.isEmpty) {
      throw const ApiException('Checkout completed but payment id missing.');
    }

    return paymentId;
  }

  @override
  Future<CoursePurchaseRecord> verifyPin({
    required String courseId,
    required String courseTitle,
    required String paymentId,
    required String pin,
  }) async {
    if (!await _hasAccessToken()) {
      if (ApiConfig.useMockPaymentMethods) {
        return _localStore.verifyPin(
          courseId: courseId,
          courseTitle: courseTitle,
          paymentId: paymentId,
          pin: pin,
        );
      }
      throw const ApiException(
        'POST /payments/verify-pin was not sent because the login token is missing. Please log in again.',
      );
    }

    final body = await _postVerifyPin(paymentId: paymentId, pin: pin);

    final record = _parsePurchaseFromVerifyPin(
      body,
      courseId: courseId,
      courseTitle: courseTitle,
      paymentId: paymentId,
    );
    await _localStore.savePurchase(record);
    return record;
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
  }

  Future<dynamic> _postCheckout({
    required String courseId,
    required PaymentCheckoutRequest request,
  }) async {
    try {
      return await _apiClient.postJson(
        ApiEndpoints.payments.checkout,
        body: request.toMap(courseId: courseId),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        throw const ApiException(
          'Your session has expired. Please log in again before checking out.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  Future<dynamic> _postVerifyPin({
    required String paymentId,
    required String pin,
  }) async {
    try {
      return await _apiClient.postJson(
        ApiEndpoints.payments.verifyPin,
        body: <String, dynamic>{
          'payment_id': paymentId,
          'pin': pin,
        },
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        throw const ApiException(
          'Your session has expired. Please log in again before confirming the payment.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  List<CoursePurchaseRecord> _parsePurchasesFromMyCourses(dynamic body) {
    final payload = unwrapBody(body);
    final list = payload is List
        ? payload
        : readList(asMap(payload), const ['courses', 'my_courses', 'data']);

    return list.map((item) {
      final root = asMap(item);
      final course = readMap(root, const ['course']);
      final source = course.isEmpty ? root : course;
      final courseId = readString(
        source,
        const ['id', 'slug'],
        fallback: readString(root, const ['course_id']),
      );
      final courseTitle = readString(
        source,
        const ['title', 'name'],
        fallback: readString(root, const ['course_title', 'title', 'name']),
      );

      return CoursePurchaseRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        isPurchased: true,
        purchaseId: readString(
          root,
          const ['purchase_id'],
          fallback: readString(root, const ['id'], fallback: courseId),
        ),
        purchasedAt: readDateTime(
          root,
          const ['purchased_at', 'created_at'],
        ),
      );
    }).where((record) {
      return record.courseId.trim().isNotEmpty ||
          record.courseTitle.trim().isNotEmpty;
    }).toList();
  }

  CoursePurchaseRecord _parsePurchaseFromVerifyPin(
    dynamic body, {
    required String courseId,
    required String courseTitle,
    required String paymentId,
  }) {
    final payload = asMap(unwrapBody(body));
    final payment = readMap(payload, const ['payment']);
    final source = payment.isEmpty ? payload : payment;
    final paidAt = readDateTime(
      source,
      const ['paid_at', 'completed_at', 'updated_at', 'created_at'],
    );

    final purchased = readBool(
      source,
      const ['success', 'completed', 'paid'],
      fallback: true,
    );

    return CoursePurchaseRecord(
      courseId: courseId,
      courseTitle: courseTitle,
      isPurchased: purchased,
      purchaseId: readString(
        source,
        const ['id'],
        fallback: readString(payload, const ['payment_id'], fallback: paymentId),
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
