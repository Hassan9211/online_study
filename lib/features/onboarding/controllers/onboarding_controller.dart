import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/illustrations.dart';

class OnboardingController extends GetxController {
  final List<OnboardingItem> items = const [
    OnboardingItem(
      title: 'Numerous free\ntrial courses',
      description: 'Free courses for you to\nfind your way to learning',
      illustration: TrialCoursesIllustration(),
    ),
    OnboardingItem(
      title: 'Quick and easy\nlearning',
      description:
          'Easy and fast learning at\nany time to help you\nimprove various skills',
      illustration: QuickLearningIllustration(),
    ),
    OnboardingItem(
      title: 'Create your own\nstudy plan',
      description:
          'Study according to the\nstudy plan, make study\nmore motivated',
      illustration: StudyPlanIllustration(),
      showActions: true,
    ),
  ];

  final RxInt currentPage = 0.obs;
  final RxInt animationDirection = 1.obs;

  int get totalPages => items.length;
  OnboardingItem get currentItem => items[currentPage.value];

  void nextPage() {
    if (currentPage.value >= totalPages - 1) {
      return;
    }

    animationDirection.value = 1;
    currentPage.value++;
  }

  void previousPage() {
    if (currentPage.value <= 0) {
      return;
    }

    animationDirection.value = -1;
    currentPage.value--;
  }

  void goToPage(int index) {
    if (index < 0 || index >= totalPages || index == currentPage.value) {
      return;
    }

    animationDirection.value = index > currentPage.value ? 1 : -1;
    currentPage.value = index;
  }

  void skipToLastPage() {
    goToPage(totalPages - 1);
  }

  void handleSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() < 150) {
      return;
    }

    if (velocity < 0) {
      nextPage();
      return;
    }

    previousPage();
  }
}

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.illustration,
    this.showActions = false,
  });

  final String title;
  final String description;
  final Widget illustration;
  final bool showActions;
}
