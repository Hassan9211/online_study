import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/product_design_course_controller.dart';
import '../models/product_design_course_data.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  void _openCourse(BuildContext context, _MyCourseCardData course) {
    if (course.routeName != null) {
      Get.toNamed(course.routeName!);
      return;
    }

    Get.snackbar(
      course.title,
      'Is course ka detail screen hum next step me bhi add kar sakte hain.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  Future<void> _showClockingDialog(BuildContext context) {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC55566E),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clocking in!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GOOD JOB!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ClockingStat(
                            label: 'Learned today',
                            value: '46',
                            suffix: 'min',
                          ),
                        ),
                        Expanded(
                          child: _ClockingStat(
                            label: 'totally hours',
                            value: '468',
                            suffix: 'hrs',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _ClockingStat(
                      label: 'Totally days',
                      value: '554',
                      suffix: 'days',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Record of this week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _WeekDayBadge(label: '1', isActive: true),
                        _WeekDayBadge(label: '2', isActive: true),
                        _WeekDayBadge(label: '3', isActive: true),
                        _WeekDayBadge(label: '4', isActive: true),
                        _WeekDayBadge(label: '5'),
                        _WeekDayBadge(label: '6'),
                        _WeekDayBadge(label: '7'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'Share',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Get.snackbar(
                          'Shared',
                          'Your learning progress is ready to share.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                          colorText: AppColors.heading,
                          margin: const EdgeInsets.all(14),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () => Navigator.of(dialogContext).pop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ProductDesignCourseController>(
      builder: (controller) {
        final courses = <_MyCourseCardData>[
          _MyCourseCardData(
            title: 'Product\nDesign v1.0',
            completedCount: controller.isPurchased
                ? productDesignLessons.length
                : productDesignFreePreviewCount,
            totalCount: productDesignLessons.length,
            backgroundColor: const Color(0xFFFFE4EC),
            progressColor: const Color(0xFFF06F9A),
            actionColor: const Color(0xFFF06F9A),
            routeName: AppRoutes.productDesignCourse,
          ),
          const _MyCourseCardData(
            title: 'Java\nDevelopment',
            completedCount: 12,
            totalCount: 18,
            backgroundColor: Color(0xFFD8E8FF),
            progressColor: Color(0xFF7E8FFF),
            actionColor: AppColors.primary,
          ),
          const _MyCourseCardData(
            title: 'Visual Design',
            completedCount: 10,
            totalCount: 16,
            backgroundColor: Color(0xFFD7F3EE),
            progressColor: Color(0xFF59B8AA),
            actionColor: Color(0xFF3D9D92),
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 54) / 2;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
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
                                Icons.visibility_off_outlined,
                                color: AppColors.heading,
                                size: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'My courses',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.heading,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Learned today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showClockingDialog(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.heading,
                              ),
                              children: [
                                const TextSpan(
                                  text: '46min',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / 60min',
                                  style: TextStyle(
                                    color: AppColors.mutedText.withValues(
                                      alpha: 0.95,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                color: const Color(0xFFF0EFF7),
                              ),
                              FractionallySizedBox(
                                widthFactor: 46 / 60,
                                child: Container(
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFD6C8),
                                        AppColors.warmAccent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 14,
                        runSpacing: 18,
                        children: courses.map((course) {
                          return _MyCourseCard(
                            width: cardWidth,
                            course: course,
                            onTap: () => _openCourse(context, course),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ClockingStat extends StatelessWidget {
  const _ClockingStat({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.heading,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              TextSpan(
                text: ' $suffix',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekDayBadge extends StatelessWidget {
  const _WeekDayBadge({
    required this.label,
    this.isActive = false,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : const Color(0xFFF0F0FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? Colors.white : const Color(0xFFCBCDDF),
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _MyCourseCard extends StatelessWidget {
  const _MyCourseCard({
    required this.width,
    required this.course,
    required this.onTap,
  });

  final double width;
  final _MyCourseCardData course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        course.totalCount == 0 ? 0.0 : course.completedCount / course.totalCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: course.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.heading.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 36),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 5,
                        color: course.progressColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inputText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.heading,
                        ),
                        children: [
                          TextSpan(
                            text: '${course.completedCount}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          TextSpan(
                            text: '/${course.totalCount}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: course.actionColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyCourseCardData {
  const _MyCourseCardData({
    required this.title,
    required this.completedCount,
    required this.totalCount,
    required this.backgroundColor,
    required this.progressColor,
    required this.actionColor,
    this.routeName,
  });

  final String title;
  final int completedCount;
  final int totalCount;
  final Color backgroundColor;
  final Color progressColor;
  final Color actionColor;
  final String? routeName;
}
