import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/course_catalog_controller.dart';
import '../controllers/course_purchase_controller.dart';
import '../models/course_catalog_data.dart';
import '../models/course_detail_record.dart';
import '../models/course_price_display.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  static const int _freePreviewLessonCount = 2;
  late final String _courseId;
  CourseCatalogItem? _fallbackCourse;
  late Future<CourseDetailRecord> _detailFuture;
  bool _isCourseFavourite = false;

  CourseCatalogController get _catalogController =>
      Get.find<CourseCatalogController>();
  CoursePurchaseController get _purchaseController =>
      Get.find<CoursePurchaseController>();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map? ?? <String, dynamic>{};
    final course = arguments['course'];
    if (course is CourseCatalogItem) {
      _fallbackCourse = course;
      _isCourseFavourite = course.isFavourite;
    }
    final courseId = arguments['courseId']?.toString().trim() ?? '';
    _courseId = courseId.isNotEmpty ? courseId : (_fallbackCourse?.id ?? '');
    _detailFuture = _loadDetail();
  }

  Future<CourseDetailRecord> _loadDetail() async {
    final detail = await _catalogController.loadCourseDetail(
      _courseId,
      fallbackCourse: _fallbackCourse,
    );
    _isCourseFavourite = detail.isFavourite || _isCourseFavourite;
    unawaited(
      _purchaseController.ensureCourseStatus(
        detail.id,
        title: detail.title,
        price: detail.price,
      ),
    );
    return detail;
  }

  Future<void> _toggleCourseFavourite(CourseDetailRecord detail) async {
    final nextValue = !_isCourseFavourite;
    setState(() {
      _isCourseFavourite = nextValue;
    });

    final didUpdate = await _catalogController.setCourseFavourite(
      detail.id,
      isFavourite: nextValue,
    );
    if (!mounted) {
      return;
    }

    if (!didUpdate) {
      setState(() {
        _isCourseFavourite = !nextValue;
      });
      Get.snackbar(
        'Favourite Update Failed',
        _catalogController.lastErrorMessage.isEmpty
            ? 'Could not update the favourite status right now.'
            : _catalogController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.snackbar(
      nextValue ? 'Course Saved' : 'Course Removed',
      nextValue
          ? 'This course was added to your favourites.'
          : 'This course was removed from your favourites.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  void _openLesson(CourseDetailRecord detail, int index, {required bool isPurchased}) {
    final lesson = detail.lessons[index];
    if (lesson.isLocked && !isPurchased) {
      Get.snackbar(
        'Lesson Locked',
        'This lesson is locked until the course is unlocked.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.coursePlayer,
      arguments: <String, dynamic>{
        'detail': detail.copyWith(isPurchased: isPurchased),
        'lessonIndex': index,
      },
    );
  }

  int _firstPlayableLessonIndex(CourseDetailRecord detail, {required bool isPurchased}) {
    final index = detail.lessons.indexWhere((lesson) => !lesson.isLocked || isPurchased);
    return index < 0 ? 0 : index;
  }

  bool _isCoursePurchased(CourseDetailRecord detail) {
    return detail.isPurchased ||
        _purchaseController.isPurchased(
          detail.id,
          title: detail.title,
          price: detail.price,
        );
  }

  void _openCheckout(CourseDetailRecord detail) {
    final checkoutAmount = _resolveCheckoutAmount(detail);
    Get.toNamed(
      AppRoutes.coursePayment,
      arguments: <String, dynamic>{
        'courseId': detail.id,
        'courseTitle': detail.title,
        'amountValue': checkoutAmount,
        'amountLabel': _formatCheckoutAmountLabel(checkoutAmount),
        'currencyCode': 'USD',
        'detail': detail,
      },
    );
  }

  double _resolveCheckoutAmount(CourseDetailRecord detail) {
    final detailPrice = normalizeCoursePrice(detail.price).toDouble();
    if (detailPrice.isFinite && detailPrice > 0 && detailPrice <= 100000) {
      return detailPrice;
    }

    final fallbackPrice = normalizeCoursePrice(_fallbackCourse?.price ?? 0)
        .toDouble();
    if (fallbackPrice.isFinite && fallbackPrice > 0 && fallbackPrice <= 100000) {
      return fallbackPrice;
    }

    return detailPrice > 0 ? detailPrice : 0;
  }

  String _formatCheckoutAmountLabel(double amount) {
    if (amount <= 0) {
      return 'Free';
    }

    final roundedAmount = double.parse(amount.toStringAsFixed(2));
    final hasDecimals = roundedAmount != roundedAmount.truncateToDouble();
    return hasDecimals
        ? '\$${roundedAmount.toStringAsFixed(2)}'
        : '\$${roundedAmount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: FutureBuilder<CourseDetailRecord>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load this course right now.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppPrimaryButton(
                        label: 'Try Again',
                        onPressed: () {
                          setState(() {
                            _detailFuture = _loadDetail();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            final detail = snapshot.data!;

            return GetBuilder<CoursePurchaseController>(
              builder: (_) {
                final isPurchased = _isCoursePurchased(detail);
                final primaryLabel = detail.lessons.isEmpty
                    ? 'No Lessons Yet'
                    : isPurchased
                    ? 'Start Learning'
                    : 'Buy Now';

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: Get.back,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.heading,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () => _toggleCourseFavourite(detail),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isCourseFavourite
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: AppColors.warmAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFDDE7FF),
                                    Color(0xFFF5E8FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _DetailBadge(label: detail.category),
                                      if (detail.isPopular)
                                        const _DetailBadge(label: 'Popular'),
                                      if (detail.isNew)
                                        const _DetailBadge(label: 'New'),
                                      if (!isPurchased && detail.price > 0)
                                        const _DetailBadge(label: 'Paid'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    detail.title,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: AppColors.heading,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    detail.teacher,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.inputText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    detail.description.isEmpty
                                        ? 'Course details will appear here after the backend sends them.'
                                        : detail.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.inputText,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailStatCard(
                                    title: detail.priceLabel,
                                    subtitle: 'Price',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DetailStatCard(
                                    title: '${detail.lessonCount}',
                                    subtitle: 'Lessons',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DetailStatCard(
                                    title: detail.durationHours <= 0
                                        ? '--'
                                        : '${detail.durationHours}h',
                                    subtitle: 'Duration',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Course lessons',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (!isPurchased && detail.price > 0) ...[
                              Builder(
                                builder: (context) {
                                  final freePreviewCount = detail.lessons
                                      .where((lesson) => !lesson.isLocked)
                                      .length;
                                  final resolvedFreePreviewCount =
                                      freePreviewCount > 0
                                      ? freePreviewCount
                                      : _freePreviewLessonCount;
                                  final lockedLessonCount =
                                      detail.lessonCount - resolvedFreePreviewCount;

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF6EA),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      lockedLessonCount > 0
                                          ? 'First $resolvedFreePreviewCount lessons are free. Buy this course to unlock the remaining $lockedLessonCount lessons.'
                                          : 'Buy this course to unlock all lessons.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.heading,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (detail.lessons.isEmpty)
                              const _CourseDetailEmptyLessons()
                            else
                              ...detail.lessons.asMap().entries.map((entry) {
                                final index = entry.key;
                                final lesson = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == detail.lessons.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: _CourseLessonTile(
                                    index: index + 1,
                                    lesson: lesson,
                                    isPurchased: isPurchased,
                                    onTap: () => _openLesson(
                                      detail,
                                      index,
                                      isPurchased: isPurchased,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1EE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _isCourseFavourite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: AppColors.warmAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppPrimaryButton(
                                label: primaryLabel,
                                onPressed: detail.lessons.isEmpty
                                    ? null
                                    : isPurchased
                                    ? () => _openLesson(
                                          detail,
                                          _firstPlayableLessonIndex(
                                            detail,
                                            isPurchased: isPurchased,
                                          ),
                                          isPurchased: isPurchased,
                                        )
                                    : () => _openCheckout(detail),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseLessonTile extends StatelessWidget {
  const _CourseLessonTile({
    required this.index,
    required this.lesson,
    required this.isPurchased,
    required this.onTap,
  });

  final int index;
  final CourseLessonRecord lesson;
  final bool isPurchased;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = lesson.isLocked && !isPurchased;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.heading.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFFF4F4FA)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isLocked
                    ? const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.mutedText,
                      )
                    : Text(
                        '$index',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.durationLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isLocked
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.play_circle_fill_rounded,
                size: isLocked ? 16 : 24,
                color: isLocked ? AppColors.mutedText : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailEmptyLessons extends StatelessWidget {
  const _CourseDetailEmptyLessons();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'The backend has not returned any lessons for this course yet.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedText,
          height: 1.45,
        ),
      ),
    );
  }
}
