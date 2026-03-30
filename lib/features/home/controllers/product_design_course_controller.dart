import 'dart:async';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_endpoints.dart';
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
    _loadPurchase();
    _preloadLessonDurations();
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
    await _purchaseRepository.savePurchase(_purchaseRecord);
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
        _lastErrorMessage =
            'GET /payments/methods chal gayi, lekin backend ne koi methods return nahi ki.';
      }
    } on TimeoutException {
      _lastErrorMessage =
          'Payment methods load hone me delay aa rahi hai. Aap retry kar sakte hain.';
      if (ApiConfig.useMockPaymentMethods && _paymentMethods.isEmpty) {
        _paymentMethods = _fallbackPaymentMethods;
      }
    } catch (error) {
      _lastErrorMessage = error.toString();
      if (ApiConfig.useMockPaymentMethods && _paymentMethods.isEmpty) {
        _paymentMethods = _fallbackPaymentMethods;
      }
    } finally {
      _isLoadingPaymentMethods = false;
      update();
    }
  }

  Future<bool> startCheckout({required String paymentMethodId}) async {
    _lastErrorMessage = '';
    try {
      _pendingPaymentId = await _purchaseRepository.createCheckout(
        paymentMethodId: paymentMethodId,
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
