import '../models/onboarding_slide_record.dart';

abstract interface class OnboardingContentRepository {
  Future<List<OnboardingSlideRecord>> loadSlides();
}
