class ProductDesignLesson {
  const ProductDesignLesson({
    required this.title,
    required this.fallbackDurationLabel,
    required this.assetPath,
  });

  final String title;
  final String fallbackDurationLabel;
  final String assetPath;
}

const String productDesignHeroTitle = 'ProductDesign v1.0';
const String productDesignCourseTitle = 'Product Design v1.0';
const String productDesignCoursePriceLabel = '\$74.00';
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
    title: 'Welcome to the Course',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/welcome_to_the_course.mp4',
  ),
  ProductDesignLesson(
    title: 'Process overview',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/process_overview.mp4',
  ),
  ProductDesignLesson(
    title: 'Discovery',
    fallbackDurationLabel: '6:10 mins',
    assetPath: 'assets/videos/discovery.mp4',
  ),
  ProductDesignLesson(
    title: 'Wireframe Practice',
    fallbackDurationLabel: '8:40 mins',
    assetPath: 'assets/videos/wireframe_practice.mp4',
  ),
  ProductDesignLesson(
    title: 'Design Challenge',
    fallbackDurationLabel: '9:15 mins',
    assetPath: 'assets/videos/design_challenge.mp4',
  ),
  ProductDesignLesson(
    title: 'Prototype Walkthrough',
    fallbackDurationLabel: '7:32 mins',
    assetPath: 'assets/videos/prototype_walkthrough.mp4',
  ),
  ProductDesignLesson(
    title: 'User Flow Review',
    fallbackDurationLabel: '5:48 mins',
    assetPath: 'assets/videos/user_flow_review.mp4',
  ),
  ProductDesignLesson(
    title: 'Final Design Polish',
    fallbackDurationLabel: '8:06 mins',
    assetPath: 'assets/videos/final_design_polish.mp4',
  ),
  ProductDesignLesson(
    title: 'Export and Handoff',
    fallbackDurationLabel: '6:54 mins',
    assetPath: 'assets/videos/export_and_handoff.mp4',
  ),
];
