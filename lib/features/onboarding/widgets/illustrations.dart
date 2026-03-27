import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TrialCoursesIllustration extends StatelessWidget {
  const TrialCoursesIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return IllustrationShell(
      backgroundColor: AppColors.cardBlue,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 12,
            right: 12,
            bottom: 2,
            child: _GroundShadow(color: AppColors.softBlueShadow),
          ),
          const Positioned(
            top: 4,
            left: 24,
            child: _IconBubble(
              icon: Icons.favorite_rounded,
              backgroundColor: Colors.white,
              iconColor: AppColors.primary,
            ),
          ),
          const Positioned(
            top: 22,
            right: 10,
            child: _IconBubble(
              icon: Icons.chat_bubble_rounded,
              backgroundColor: Colors.white,
              iconColor: AppColors.skyLine,
            ),
          ),
          Positioned(
            left: 24,
            top: 48,
            child: Transform.rotate(
              angle: -0.34,
              child: const _Limb(width: 18, height: 70, color: AppColors.skin),
            ),
          ),
          const Positioned(
            left: 40,
            top: 24,
            child: _HairShape(width: 86, height: 118, color: AppColors.heading),
          ),
          const Positioned(
            left: 58,
            top: 40,
            child: _Face(width: 42, height: 44, color: AppColors.skin),
          ),
          const Positioned(
            left: 48,
            top: 80,
            child: _Torso(width: 108, height: 70, color: AppColors.primary),
          ),
          Positioned(
            left: 84,
            top: 90,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 66,
            top: 102,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickLearningIllustration extends StatelessWidget {
  const QuickLearningIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return IllustrationShell(
      backgroundColor: AppColors.cardMint,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 10,
            left: 16,
            child: Icon(
              Icons.send_rounded,
              size: 26,
              color: AppColors.paperPlane,
            ),
          ),
          const Positioned(
            left: 12,
            top: 26,
            child: _RoundHair(size: 64, color: AppColors.orangeHair),
          ),
          const Positioned(
            left: 32,
            top: 44,
            child: _Face(width: 34, height: 40, color: AppColors.deepSkin),
          ),
          const Positioned(
            left: 18,
            top: 82,
            child: _Torso(width: 94, height: 68, color: AppColors.primary),
          ),
          Positioned(
            left: 94,
            top: 52,
            child: Transform.rotate(
              angle: -0.1,
              child: const _Phone(color: AppColors.phone),
            ),
          ),
          Positioned(
            left: 78,
            top: 50,
            child: Transform.rotate(
              angle: -0.16,
              child: const _Limb(
                width: 22,
                height: 88,
                color: AppColors.armOrange,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 54,
            child: Transform.rotate(
              angle: 0.08,
              child: const _Limb(
                width: 20,
                height: 74,
                color: AppColors.armOrange,
              ),
            ),
          ),
          Positioned(
            left: 52,
            top: 112,
            child: Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudyPlanIllustration extends StatelessWidget {
  const StudyPlanIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 176,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 6,
            left: 52,
            child: Container(
              width: 96,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardLavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  Icon(Icons.circle, size: 8, color: AppColors.heading),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: AppColors.heading,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: 30,
            child: Container(
              width: 48,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.softPanel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.dark_mode_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 84,
            top: 30,
            child: Container(
              width: 18,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.heading,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            left: 72,
            top: 42,
            child: _Face(width: 34, height: 38, color: AppColors.skin),
          ),
          const Positioned(left: 64, top: 74, child: _StudyDress()),
          const Positioned(left: 92, top: 74, child: _StudyVest()),
          Positioned(
            left: 38,
            top: 98,
            child: Container(
              width: 86,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.laptop,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.softBlueShadow,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.circle, size: 8, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 26,
            bottom: 24,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.heading.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IllustrationShell extends StatelessWidget {
  const IllustrationShell({
    super.key,
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      height: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(34),
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 22,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }
}

class _GroundShadow extends StatelessWidget {
  const _GroundShadow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
      ),
    );
  }
}

class _HairShape extends StatelessWidget {
  const _HairShape({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(36),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(44),
        ),
      ),
    );
  }
}

class _RoundHair extends StatelessWidget {
  const _RoundHair({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width / 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.28,
            top: height * 0.42,
            child: const _Dot(color: AppColors.heading, size: 4),
          ),
          Positioned(
            right: width * 0.28,
            top: height * 0.42,
            child: const _Dot(color: AppColors.heading, size: 4),
          ),
          Positioned(
            left: width * 0.34,
            right: width * 0.34,
            bottom: height * 0.18,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.heading,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Torso extends StatelessWidget {
  const _Torso({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    );
  }
}

class _Limb extends StatelessWidget {
  const _Limb({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StudyDress extends StatelessWidget {
  const _StudyDress();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 74,
      decoration: const BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    );
  }
}

class _StudyVest extends StatelessWidget {
  const _StudyVest();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
    );
  }
}
