import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/onboarding_controller.dart';
import 'page_indicator.dart';

class OnboardingPageLayout extends GetView<OnboardingController> {
  const OnboardingPageLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerRight,
                child: controller.currentItem.showActions
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: controller.skipToLastPage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: AppColors.mutedText,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final beginOffset = Offset(
                            controller.animationDirection.value * 0.12,
                            0,
                          );

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: beginOffset,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [...previousChildren, ?currentChild],
                          );
                        },
                        child: _OnboardingContent(
                          key: ValueKey(controller.currentPage.value),
                          item: controller.currentItem,
                          theme: theme,
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => OnboardingPageIndicator(
                    itemCount: controller.totalPages,
                    currentIndex: controller.currentPage.value,
                    onDotTap: controller.goToPage,
                  ),
                ),
                const SizedBox(height: 34),
                Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: controller.currentItem.showActions
                        ? Row(
                            key: const ValueKey('actions'),
                            children: [
                              Expanded(
                                child: AppPrimaryButton(
                                  label: 'Sign up',
                                  onPressed: () => Get.toNamed(AppRoutes.signUp),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Log in',
                                  onPressed: () => Get.toNamed(AppRoutes.logIn),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            key: ValueKey('empty-actions'),
                            height: 48,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    super.key,
    required this.item,
    required this.theme,
  });

  final OnboardingItem item;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        item.illustration,
        const SizedBox(height: 30),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          item.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.mutedText,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
