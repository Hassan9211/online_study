import 'dart:async';

import 'package:get/get.dart';

import 'home_dashboard_controller.dart';
import '../models/course_purchase_record.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import '../repositories/course_purchase_repository.dart';

class CoursePurchaseController extends GetxController {
  CoursePurchaseController(this._repository);

  static const List<PaymentMethodRecord> _fallbackPaymentMethods =
      <PaymentMethodRecord>[
        PaymentMethodRecord(
          id: 'local_card_1',
          label: 'My card',
          maskedNumber: '**** **** **** 4829',
        ),
        PaymentMethodRecord(
          id: 'local_card_2',
          label: 'Work card',
          maskedNumber: '**** **** **** 2641',
        ),
        PaymentMethodRecord(
          id: 'local_card_3',
          label: 'Family card',
          maskedNumber: '**** **** **** 3156',
        ),
      ];

  final CoursePurchaseRepository _repository;

  List<CoursePurchaseRecord> _purchases = const <CoursePurchaseRecord>[];
  List<PaymentMethodRecord> _paymentMethods = const <PaymentMethodRecord>[];
  final Map<String, String> _pendingPaymentIds = <String, String>{};
  bool _isLoadingPurchases = false;
  bool _isLoadingPaymentMethods = false;
  String _lastErrorMessage = '';

  List<PaymentMethodRecord> get paymentMethods =>
      List<PaymentMethodRecord>.unmodifiable(_paymentMethods);
  bool get isLoadingPurchases => _isLoadingPurchases;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  String get lastErrorMessage => _lastErrorMessage;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    _purchases = await _repository.loadCachedPurchases();
    update();
    await refreshPurchases();
  }

  bool isPurchased(
    String courseId, {
    String title = '',
    int price = 1,
  }) {
    if (price <= 0) {
      return true;
    }

    final record = _findRecord(courseId, title: title);
    return record?.isPurchased ?? false;
  }

  Future<void> ensureCourseStatus(
    String courseId, {
    String title = '',
    int price = 1,
  }) async {
    if (price <= 0) {
      return;
    }
    if (_findRecord(courseId, title: title)?.isPurchased == true) {
      return;
    }
    await refreshPurchases();
  }

  Future<void> refreshPurchases() async {
    if (_isLoadingPurchases) {
      return;
    }

    _isLoadingPurchases = true;
    _lastErrorMessage = '';
    update();

    try {
      _purchases = await _repository.loadPurchases();
    } catch (error) {
      _lastErrorMessage = error.toString();
    } finally {
      _isLoadingPurchases = false;
      update();
    }
  }

  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    if (_isLoadingPaymentMethods ||
        (!forceRefresh && _paymentMethods.isNotEmpty)) {
      return;
    }

    _isLoadingPaymentMethods = true;
    _lastErrorMessage = '';
    update();

    try {
      final methods = await _repository
          .loadPaymentMethods()
          .timeout(const Duration(seconds: 8));
      if (methods.isNotEmpty) {
        _paymentMethods = methods;
      } else {
        _paymentMethods = _fallbackPaymentMethods;
        _lastErrorMessage =
            'Live payment methods are unavailable right now. Showing saved cards for now.';
      }
    } on TimeoutException {
      if (_paymentMethods.isEmpty) {
        _paymentMethods = _fallbackPaymentMethods;
      }
      _lastErrorMessage =
          'Payment methods are taking longer than expected to load. Showing saved cards for now.';
    } catch (error) {
      final authError = _isAuthError(error);
      if (authError) {
        _paymentMethods = const <PaymentMethodRecord>[];
      }
      if (_paymentMethods.isEmpty && !authError) {
        _paymentMethods = _fallbackPaymentMethods;
      }
      _lastErrorMessage = authError
          ? (error.toString().trim().isEmpty
                ? 'Your session has expired. Please log in again to continue with checkout.'
                : error.toString())
          : (error.toString().trim().isEmpty
                ? 'Could not load live payment methods. Showing saved cards for now.'
                : '${error.toString()} Showing saved cards for now.');
    } finally {
      _isLoadingPaymentMethods = false;
      update();
    }
  }

  Future<bool> startCheckout({
    required String courseId,
    required PaymentCheckoutRequest request,
  }) async {
    _lastErrorMessage = '';
    try {
      _pendingPaymentIds[courseId] = await _repository.createCheckout(
        courseId: courseId,
        request: request,
      );
      update();
      return true;
    } catch (error) {
      _pendingPaymentIds.remove(courseId);
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  Future<bool> confirmPurchase({
    required String courseId,
    required String courseTitle,
    required String pin,
  }) async {
    final paymentId = _pendingPaymentIds[courseId] ?? '';
    if (paymentId.isEmpty) {
      return false;
    }

    _lastErrorMessage = '';
    try {
      final record = await _repository.verifyPin(
        courseId: courseId,
        courseTitle: courseTitle,
        paymentId: paymentId,
        pin: pin,
      );
      _pendingPaymentIds.remove(courseId);
      _upsertPurchase(record);
      update();
      if (Get.isRegistered<HomeDashboardController>()) {
        unawaited(Get.find<HomeDashboardController>().refreshAll());
      }
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  Future<void> resetForSignedOutUser() async {
    _purchases = const <CoursePurchaseRecord>[];
    _paymentMethods = const <PaymentMethodRecord>[];
    _pendingPaymentIds.clear();
    _isLoadingPurchases = false;
    _isLoadingPaymentMethods = false;
    _lastErrorMessage = '';
    await _repository.clearCachedState();
    update();
  }

  CoursePurchaseRecord? _findRecord(String courseId, {String title = ''}) {
    for (final record in _purchases) {
      if (record.matches(id: courseId, title: title)) {
        return record;
      }
    }
    return null;
  }

  void _upsertPurchase(CoursePurchaseRecord record) {
    _purchases = <CoursePurchaseRecord>[
      record,
      ..._purchases.where((item) {
        return !item.matches(id: record.courseId, title: record.courseTitle);
      }),
    ];
  }

  bool _isAuthError(Object error) {
    final message = error.toString().trim().toLowerCase();
    return message.contains('unauthenticated') ||
        message.contains('session has expired') ||
        message.contains('log in again') ||
        message.contains('token is missing');
  }
}
