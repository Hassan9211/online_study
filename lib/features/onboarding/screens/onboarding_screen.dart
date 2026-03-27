import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_page_layout.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: controller.handleSwipeEnd,
              child: const OnboardingPageLayout(),
            ),
          ),
        ),
      ),
    );
  }
}
