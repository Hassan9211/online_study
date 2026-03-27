import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/product_design_course_controller.dart';
import '../models/product_design_course_data.dart';

class ProductDesignCourseScreen extends StatelessWidget {
  const ProductDesignCourseScreen({super.key});

  void _openLesson(
    ProductDesignCourseController controller,
    int index,
  ) {
    if (controller.isLessonLocked(index)) {
      Get.snackbar(
        'Video Locked',
        'Buy Now k baad yeh video play hogi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.productDesignPlayer,
      arguments: {
        'lessonIndex': index,
      },
    );
  }

  void _buyCourse(ProductDesignCourseController controller) {
    if (controller.isPurchased) {
      return;
    }

    Get.toNamed(AppRoutes.productDesignPayment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ProductDesignCourseController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF5F7),
          bottomNavigationBar: _CourseBottomBar(
            isPurchased: controller.isPurchased,
            onPressed: controller.isPurchased
                ? null
                : () => _buyCourse(controller),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Expanded(
                  flex: 1,
                  child: _CoursePosterHeader(),
                ),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.heading.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 124),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productDesignCourseTitle,
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        color: AppColors.heading,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      controller.courseMetaLabel,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                productDesignCoursePriceLabel,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'About this course',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productDesignCourseDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                              height: 1.45,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Icon(
                              Icons.visibility_off_outlined,
                              color: AppColors.heading,
                              size: 17,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...List.generate(productDesignLessons.length, (index) {
                            final lesson = productDesignLessons[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == productDesignLessons.length - 1
                                        ? 0
                                        : 18,
                              ),
                              child: _CourseLessonRow(
                                index: index,
                                title: lesson.title,
                                durationLabel:
                                    controller.lessonDurationLabel(index),
                                isLocked: controller.isLessonLocked(index),
                                isHighlightedDuration:
                                    index == 0 &&
                                    !controller.isLessonLocked(index),
                                onTap: () => _openLesson(controller, index),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoursePosterHeader extends StatelessWidget {
  const _CoursePosterHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: const Color(0xFFFFEEF4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.heading,
                    size: 20,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 86,
              child: SizedBox(
                width: 116,
                height: 130,
                child: CustomPaint(
                  painter: _HeroTrailPainter(),
                ),
              ),
            ),
            const Positioned(
              left: 114,
              top: 132,
              child: RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: 28,
                  height: 20,
                  child: CustomPaint(
                    painter: _PaperPlanePainter(),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              top: 54,
              child: _BestsellerTag(),
            ),
            Positioned(
              left: 0,
              top: 98,
              child: Text(
                productDesignHeroTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const Positioned(
              right: -2,
              bottom: -4,
              child: _PosterIllustration(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseBottomBar extends StatelessWidget {
  const _CourseBottomBar({
    required this.isPurchased,
    required this.onPressed,
  });

  final bool isPurchased;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.star_border_rounded,
                  color: AppColors.warmAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(isPurchased ? 'Purchased' : 'Buy Now'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestsellerTag extends StatelessWidget {
  const _BestsellerTag();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketTagClipper(),
      child: Container(
        width: 76,
        height: 22,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 10),
        color: const Color(0xFFFFD437),
        child: Text(
          'BESTSELLER',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}

class _PosterIllustration extends StatelessWidget {
  const _PosterIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 176,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 22,
            top: 18,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 14,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 38,
            top: 12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _SparkPainter(),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 30,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 22,
                height: 102,
                decoration: BoxDecoration(
                  color: AppColors.armOrange,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 18,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.skin,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 48,
            top: 34,
            child: _CharacterHead(),
          ),
          Positioned(
            left: 42,
            top: 72,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 20,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.armOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 58,
            top: 72,
            child: _PeaceHand(),
          ),
          Positioned(
            left: 30,
            bottom: 0,
            child: Container(
              width: 58,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.armOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 68,
            bottom: 0,
            child: SizedBox(
              width: 92,
              height: 102,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ShirtScribblePainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterHead extends StatelessWidget {
  const _CharacterHead();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            top: 20,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.skin,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 62,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.orangeHair,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(14),
                ),
              ),
            ),
          ),
          Positioned(
            left: 42,
            top: 10,
            child: Container(
              width: 18,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.orangeHair,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            top: 36,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.heading,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 40,
            top: 36,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.heading,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 44,
            child: Container(
              width: 16,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.deepSkin,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeaceHand extends StatelessWidget {
  const _PeaceHand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.skin,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 5,
                height: 15,
                decoration: BoxDecoration(
                  color: AppColors.skin,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 1,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 5,
                height: 15,
                decoration: BoxDecoration(
                  color: AppColors.skin,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseLessonRow extends StatelessWidget {
  const _CourseLessonRow({
    required this.index,
    required this.title,
    required this.durationLabel,
    required this.isLocked,
    required this.isHighlightedDuration,
    required this.onTap,
  });

  final int index;
  final String title;
  final String durationLabel;
  final bool isLocked;
  final bool isHighlightedDuration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            '${index + 1}'.padLeft(2, '0'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFCDD1E1),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _LessonDurationLabel(
                    durationLabel: durationLabel,
                    isLocked: isLocked,
                    isHighlighted: isHighlightedDuration,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFCCD4FF) : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Icon(
              isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: isLocked ? 21 : 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonDurationLabel extends StatelessWidget {
  const _LessonDurationLabel({
    required this.durationLabel,
    required this.isLocked,
    required this.isHighlighted,
  });

  final String durationLabel;
  final bool isLocked;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = durationLabel.split(' ');
    final timeLabel = parts.isEmpty ? durationLabel : parts.first;
    final unitLabel = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    if (!isLocked && isHighlighted && unitLabel.isNotEmpty) {
      return Row(
        children: [
          Text(
            timeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.play_arrow_rounded,
            size: 12,
            color: AppColors.warmAccent,
          ),
          const SizedBox(width: 2),
          Text(
            unitLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      durationLabel,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isLocked ? AppColors.mutedText : const Color(0xFFB5BACB),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TicketTagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 12, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 12, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroTrailPainter extends CustomPainter {
  const _HeroTrailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final path = Path()
      ..moveTo(size.width * 0.88, 0)
      ..quadraticBezierTo(
        size.width * 0.14,
        size.height * 0.08,
        size.width * 0.34,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.92,
        size.width * 0.08,
        size.height,
      );

    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        const dashLength = 6.0;
        const gapLength = 5.0;

        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperPlanePainter extends CustomPainter {
  const _PaperPlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = const Color(0xFFF7FAFF);
    final strokePaint = Paint()
      ..color = const Color(0xFFE4E9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final plane = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.66, size.height)
      ..close();

    final fold = Path()
      ..moveTo(size.width * 0.16, size.height * 0.56)
      ..lineTo(size.width * 0.72, size.height * 0.14)
      ..lineTo(size.width * 0.54, size.height * 0.76);

    canvas.drawPath(plane, fillPaint);
    canvas.drawPath(plane, strokePaint);
    canvas.drawPath(fold, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB6C4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height * 0.22),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.78),
      Offset(size.width * 0.5, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.22, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.14),
      Offset(size.width * 0.3, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.7),
      Offset(size.width * 0.86, size.height * 0.86),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.86),
      Offset(size.width * 0.3, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.86, size.height * 0.14),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShirtScribblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pathOne = Path()
      ..moveTo(size.width * 0.2, size.height * 0.24)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.04,
        size.width * 0.56,
        size.height * 0.16,
        size.width * 0.46,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.5,
        size.width * 0.58,
        size.height * 0.62,
        size.width * 0.76,
        size.height * 0.46,
      );

    final pathTwo = Path()
      ..moveTo(size.width * 0.34, size.height * 0.62)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.76,
        size.width * 0.34,
        size.height * 0.96,
        size.width * 0.58,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.76,
        size.width * 0.78,
        size.height * 0.86,
        size.width * 0.72,
        size.height * 0.94,
      );

    canvas.drawPath(pathOne, paint);
    canvas.drawPath(pathTwo, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
