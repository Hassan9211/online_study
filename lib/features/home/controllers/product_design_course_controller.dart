import 'dart:async';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'home_dashboard_controller.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import '../models/product_design_course_data.dart';
import '../models/product_design_purchase_record.dart';
import '../repositories/product_design_purchase_repository.dart';

class ProductDesignCourseController extends GetxController {
  ProductDesignCourseController(this._purchaseRepository);

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

  final ProductDesignPurchaseRepository _purchaseRepository;

  ProductDesignPurchaseRecord _purchaseRecord =
      const ProductDesignPurchaseRecord.empty();
  List<PaymentMethodRecord> _paymentMethods = const <PaymentMethodRecord>[];
  final Map<int, Duration> _lessonDurations = <int, Duration>{};
  bool _isLoadingDurations = false;
  bool _isLoadingPaymentMethods = false;
  String _pendingPaymentId = '';
  String _lastErrorMessage = '';

  bool get isPurchased => _purchaseRecord.isPurchased;
  bool get isLoadingDurations => _isLoadingDurations;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  List<PaymentMethodRecord> get paymentMethods =>
      List<PaymentMethodRecord>.unmodifiable(_paymentMethods);
  String get lastErrorMessage => _lastErrorMessage;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
    unawaited(_preloadLessonDurations());
  }

  Future<void> _bootstrap() async {
    _purchaseRecord = await _purchaseRepository.loadCachedPurchase();
    update();
    await _loadPurchase();
  }

  bool isLessonLocked(int index) {
    return index >= productDesignFreePreviewCount && !isPurchased;
  }

  String lessonDurationLabel(int index) {
    final actualDuration = _lessonDurations[index];
    if (actualDuration != null) {
      return _formatLessonDuration(actualDuration);
    }
    return productDesignLessons[index].fallbackDurationLabel;
  }

  String get courseMetaLabel {
    if (_lessonDurations.length == productDesignLessons.length) {
      final totalDuration = _lessonDurations.values.fold<Duration>(
        Duration.zero,
        (sum, item) => sum + item,
      );
      return '${_formatCourseDuration(totalDuration)} - ${productDesignLessons.length} Lessons';
    }

    return productDesignCourseMetaLabel;
  }

  Future<void> purchaseCourse() async {
    _purchaseRecord = await _purchaseRepository.verifyPin(
      paymentId: 'pd_${DateTime.now().millisecondsSinceEpoch}',
      pin: '',
    );
    update();
  }

  Future<void> reset() async {
    _purchaseRecord = const ProductDesignPurchaseRecord.empty();
    update();
    await _purchaseRepository.savePurchase(_purchaseRecord);
    if (Get.isRegistered<HomeDashboardController>()) {
      unawaited(Get.find<HomeDashboardController>().refreshAll());
    }
  }

  Future<void> resetForSignedOutUser() async {
    _purchaseRecord = const ProductDesignPurchaseRecord.empty();
    _paymentMethods = const <PaymentMethodRecord>[];
    _pendingPaymentId = '';
    _isLoadingPaymentMethods = false;
    _lastErrorMessage = '';
    await _purchaseRepository.clearCachedState();
    update();
  }

  Future<void> _loadPurchase() async {
    _purchaseRecord = await _purchaseRepository.loadPurchase();
    update();
  }

  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    if (_isLoadingPaymentMethods || (!forceRefresh && _paymentMethods.isNotEmpty)) {
      return;
    }

    _isLoadingPaymentMethods = true;
    _lastErrorMessage = '';
    update();

    try {
      final methods = await _purchaseRepository
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

  Future<bool> startCheckout({required PaymentCheckoutRequest request}) async {
    _lastErrorMessage = '';
    try {
      _pendingPaymentId = await _purchaseRepository.createCheckout(
        request: request,
      );
      update();
      return true;
    } catch (error) {
      _pendingPaymentId = '';
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  Future<bool> confirmPurchase({required String pin}) async {
    if (_pendingPaymentId.isEmpty) {
      return false;
    }

    _lastErrorMessage = '';
    try {
      _purchaseRecord = await _purchaseRepository.verifyPin(
        paymentId: _pendingPaymentId,
        pin: pin,
      );
      _pendingPaymentId = '';
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

  Future<void> _preloadLessonDurations() async {
    if (_isLoadingDurations || _lessonDurations.length == productDesignLessons.length) {
      return;
    }

    _isLoadingDurations = true;
    update();

    for (var index = 0; index < productDesignLessons.length; index++) {
      if (_lessonDurations.containsKey(index)) {
        continue;
      }

      final controller = VideoPlayerController.asset(
        productDesignLessons[index].assetPath,
      );

      try {
        await controller.initialize();
        final duration = controller.value.duration;
        if (duration > Duration.zero) {
          _lessonDurations[index] = duration;
          update();
        }
      } catch (_) {
        // Keep the fallback label if metadata loading fails for any asset.
      } finally {
        await controller.dispose();
      }
    }

    _isLoadingDurations = false;
    update();
  }

  bool _isAuthError(Object error) {
    final message = error.toString().trim().toLowerCase();
    return message.contains('unauthenticated') ||
        message.contains('session has expired') ||
        message.contains('log in again') ||
        message.contains('token is missing');
  }
}

String _formatLessonDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

  if (minutes <= 0) {
    return '$totalSeconds sec';
  }

  return '$minutes:$seconds mins';
}

String _formatCourseDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '${minutes}min';
  }

  return '${hours}h ${minutes}min';
}
