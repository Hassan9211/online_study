class FavouriteLessonRecord {
  const FavouriteLessonRecord({
    required this.id,
    required this.lessonId,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.durationLabel,
  });

  final String id;
  final String lessonId;
  final String courseId;
  final String courseTitle;
  final String title;
  final String durationLabel;
}
