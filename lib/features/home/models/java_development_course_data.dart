class JavaDevelopmentLesson {
  const JavaDevelopmentLesson({
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

const String javaDevelopmentCourseId = 'java_development';
const String javaDevelopmentCourseTitle = 'Java Development';
const int javaDevelopmentCourseLessonCount = 7;
const int javaDevelopmentCourseDurationHours = 7;
const String javaDevelopmentCourseDescription =
    'Build a confident Java foundation with practical lessons on setup, variables, conditions, loops, methods, classes, and hands-on practice.';

// The backend may identify this course using either a slug/title or a simple
// numeric id, so we accept all known variants here.
bool matchesJavaDevelopmentCourse({
  String id = '',
  String title = '',
}) {
  final normalizedId = id.trim().toLowerCase();
  if (normalizedId == javaDevelopmentCourseId ||
      normalizedId == 'java-development' ||
      normalizedId == '2') {
    return true;
  }

  return title.trim().toLowerCase() == 'java development';
}

// Java Development is shipped with bundled local MP4 assets. Preview locking is
// applied later in the repositories so the same lesson list can be reused in
// local and remote catalog flows.
const List<JavaDevelopmentLesson> javaDevelopmentLessons =
    <JavaDevelopmentLesson>[
      JavaDevelopmentLesson(
        id: 'java_basics_and_setup',
        title: 'Java Basics and Setup',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_basics_and_setup.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_variables_and_data_types',
        title: 'Variables and Data Types',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_variables_and_data_types_essentials.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_conditional_statements',
        title: 'Conditional Statements',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_conditional_statements.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_loops_in_practice',
        title: 'Loops in Practice',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_loops_in_practice.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_methods_and_parameters',
        title: 'Methods and Parameters',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_methods_and_parameters.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_classes_and_objects',
        title: 'Classes and Objects',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_classes_and_objects.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_practice_walkthrough',
        title: 'Java Practice Walkthrough',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_practice_walkthrough.mp4',
      ),
    ];
