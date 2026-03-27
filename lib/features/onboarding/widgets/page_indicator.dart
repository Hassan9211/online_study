import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.onDotTap,
  });

  final int itemCount;
  final int currentIndex;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: onDotTap == null ? null : () => onDotTap!(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: isActive ? 18 : 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.indicatorInactive,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}
