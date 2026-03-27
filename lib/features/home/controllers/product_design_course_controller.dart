import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../models/product_design_course_data.dart';
import '../models/product_design_purchase_record.dart';
import '../repositories/product_design_purchase_repository.dart';

class ProductDesignCourseController extends GetxController {
  ProductDesignCourseController(this._purchaseRepository);

  final ProductDesignPurchaseRepository _purchaseRepository;

  ProductDesignPurchaseRecord _purchaseRecord =
      const ProductDesignPurchaseRecord.empty();
  final Map<int, Duration> _lessonDurations = <int, Duration>{};
  bool _isLoadingDurations = false;

  bool get isPurchased => _purchaseRecord.isPurchased;
  bool get isLoadingDurations => _isLoadingDurations;

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
    _purchaseRecord = ProductDesignPurchaseRecord(
      isPurchased: true,
      purchaseId: 'pd_${DateTime.now().millisecondsSinceEpoch}',
      purchasedAt: DateTime.now(),
    );
    await _purchaseRepository.savePurchase(_purchaseRecord);
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
