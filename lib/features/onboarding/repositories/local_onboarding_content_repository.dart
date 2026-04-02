import '../models/onboarding_slide_record.dart';
import 'onboarding_content_repository.dart';

class LocalOnboardingContentRepository implements OnboardingContentRepository {
  static const List<OnboardingSlideRecord> _slides = <OnboardingSlideRecord>[
    OnboardingSlideRecord(
      title: 'Numerous free\ntrial courses',
      description: 'Free courses for you to\nfind your way to learning',
      illustrationKey: 'trial_courses',
    ),
    OnboardingSlideRecord(
      title: 'Quick and easy\nlearning',
      description:
          'Easy and fast learning at\nany time to help you\nimprove various skills',
      illustrationKey: 'quick_learning',
    ),
    OnboardingSlideRecord(
      title: 'Create your own\nstudy plan',
      description:
          'Study according to the\nstudy plan, make study\nmore motivated',
      illustrationKey: 'study_plan',
      showActions: true,
    ),
  ];

  @override
  Future<List<OnboardingSlideRecord>> loadSlides() async {
    return _slides;
  }
}
