class LearningActivitySnapshot {
  const LearningActivitySnapshot({
    required this.watchedTodaySeconds,
    required this.completedProductDesignLessonIds,
    required this.completedGenericLessonIdsByCourse,
  });

  const LearningActivitySnapshot.empty()
      : watchedTodaySeconds = 0,
        completedProductDesignLessonIds = const <String>{},
        completedGenericLessonIdsByCourse = const <String, Set<String>>{};

  final int watchedTodaySeconds;
  final Set<String> completedProductDesignLessonIds;
  final Map<String, Set<String>> completedGenericLessonIdsByCourse;

  int get completedProductDesignLessonsCount =>
      completedProductDesignLessonIds.length;

  int completedGenericLessonsCountFor({
    required String courseId,
    String title = '',
  }) {
    final key = _courseActivityKey(courseId: courseId, title: title);
    if (key.isEmpty) {
      return 0;
    }

    return completedGenericLessonIdsByCourse[key]?.length ?? 0;
  }
}

String _courseActivityKey({
  required String courseId,
  String title = '',
}) {
  final normalizedId = _normalizeActivitySegment(courseId);
  if (normalizedId.isNotEmpty) {
    return normalizedId;
  }

  return _normalizeActivitySegment(title);
}

String _normalizeActivitySegment(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
