import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/onboarding_slide_record.dart';
import '../repositories/onboarding_content_repository.dart';
import '../widgets/illustrations.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._repository);

  final OnboardingContentRepository _repository;
  final RxList<OnboardingItem> items = <OnboardingItem>[
    const OnboardingItem(
      title: 'Numerous free\ntrial courses',
      description: 'Free courses for you to\nfind your way to learning',
      illustration: TrialCoursesIllustration(),
    ),
    const OnboardingItem(
      title: 'Quick and easy\nlearning',
      description:
          'Easy and fast learning at\nany time to help you\nimprove various skills',
      illustration: QuickLearningIllustration(),
    ),
    const OnboardingItem(
      title: 'Create your own\nstudy plan',
      description:
          'Study according to the\nstudy plan, make study\nmore motivated',
      illustration: StudyPlanIllustration(),
      showActions: true,
    ),
  ].obs;

  final RxInt currentPage = 0.obs;
  final RxInt animationDirection = 1.obs;

  int get totalPages => items.length;
  OnboardingItem get currentItem => items[currentPage.value];

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadSlides());
  }

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

  Future<void> _loadSlides() async {
    final slides = await _repository.loadSlides();
    if (slides.isEmpty) {
      return;
    }

    items.assignAll(
      slides.asMap().entries.map((entry) {
        return _mapSlideToItem(entry.value, index: entry.key);
      }),
    );

    if (currentPage.value >= items.length) {
      currentPage.value = items.length - 1;
    }
  }

  OnboardingItem _mapSlideToItem(
    OnboardingSlideRecord slide, {
    required int index,
  }) {
    return OnboardingItem(
      title: slide.title,
      description: slide.description,
      illustration: _buildIllustration(slide.illustrationKey, index: index),
      showActions: slide.showActions,
    );
  }

  Widget _buildIllustration(String illustrationKey, {required int index}) {
    final normalizedKey = illustrationKey.trim().toLowerCase();

    if (normalizedKey.contains('quick')) {
      return const QuickLearningIllustration();
    }
    if (normalizedKey.contains('study') || normalizedKey.contains('plan')) {
      return const StudyPlanIllustration();
    }
    if (normalizedKey.contains('trial') || normalizedKey.contains('course')) {
      return const TrialCoursesIllustration();
    }

    return switch (index) {
      1 => const QuickLearningIllustration(),
      2 => const StudyPlanIllustration(),
      _ => const TrialCoursesIllustration(),
    };
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
