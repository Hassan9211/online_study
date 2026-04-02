class ProductDesignLesson {
  const ProductDesignLesson({
    required this.id,
    required this.title,
    required this.fallbackDurationLabel,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String fallbackDurationLabel;
  final String assetPath;
}

const String productDesignHeroTitle = 'ProductDesign v1.0';
const String productDesignCourseTitle = 'Product Design v1.0';
const String productDesignCoursePriceLabel = '\$74.00';
const double productDesignCoursePriceValue = 74.00;
const String productDesignCourseCurrencyCode = 'USD';
const String productDesignFallbackCourseDurationSummary = '6h 14min';
const String productDesignCourseDescription =
    'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.';

const int productDesignFreePreviewCount = 2;

int get productDesignLockedLessonCount {
  final lockedCount = productDesignLessons.length - productDesignFreePreviewCount;
  return lockedCount > 0 ? lockedCount : 0;
}

String get productDesignCourseMetaLabel =>
    '$productDesignFallbackCourseDurationSummary - ${productDesignLessons.length} Lessons';

const List<ProductDesignLesson> productDesignLessons = [
  ProductDesignLesson(
    id: 'welcome_to_the_course',
    title: 'Welcome to the Course',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/welcome_to_the_course.mp4',
  ),
  ProductDesignLesson(
    id: 'process_overview',
    title: 'Process overview',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/process_overview.mp4',
  ),
  ProductDesignLesson(
    id: 'discovery',
    title: 'Discovery',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/discovery.mp4',
  ),
  ProductDesignLesson(
    id: 'wireframe_practice',
    title: 'Wireframe Practice',
    fallbackDurationLabel: '8:40 mins',
    assetPath: 'assets/videos/wireframe_practice.mp4',
  ),
  ProductDesignLesson(
    id: 'design_challenge',
    title: 'Design Challenge',
    fallbackDurationLabel: '9:15 mins',
    assetPath: 'assets/videos/design_challenge.mp4',
  ),
  ProductDesignLesson(
    id: 'prototype_walkthrough',
    title: 'Prototype Walkthrough',
    fallbackDurationLabel: '7:32 mins',
    assetPath: 'assets/videos/prototype_walkthrough.mp4',
  ),
  ProductDesignLesson(
    id: 'user_flow_review',
    title: 'User Flow Review',
    fallbackDurationLabel: '5:48 mins',
    assetPath: 'assets/videos/user_flow_review.mp4',
  ),
  ProductDesignLesson(
    id: 'final_design_polish',
    title: 'Final Design Polish',
    fallbackDurationLabel: '8:06 mins',
    assetPath: 'assets/videos/final_design_polish.mp4',
  ),
  ProductDesignLesson(
    id: 'export_and_handoff',
    title: 'Export and Handoff',
    fallbackDurationLabel: '6:54 mins',
    assetPath: 'assets/videos/export_and_handoff.mp4',
  ),
];
