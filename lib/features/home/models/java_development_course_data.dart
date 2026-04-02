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
const String javaDevelopmentCourseDescription =
    'Build a confident Java foundation with practical lessons on syntax, data types, control flow, methods, classes, and object-oriented programming.';

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

const List<JavaDevelopmentLesson> javaDevelopmentLessons =
    <JavaDevelopmentLesson>[
      JavaDevelopmentLesson(
        id: 'java_course_intro',
        title: 'Java Course Intro',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_course_intro.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_variables_and_data_types',
        title: 'Variables and Data Types',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_variables_and_data_types.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_control_flow',
        title: 'Control Flow Basics',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_control_flow.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_methods_and_classes',
        title: 'Methods and Classes',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_methods_and_classes.mp4',
      ),
      JavaDevelopmentLesson(
        id: 'java_oop_in_practice',
        title: 'OOP in Practice',
        fallbackDurationLabel: 'Video lesson',
        assetPath: 'assets/videos/java_oop_in_practice.mp4',
      ),
    ];
