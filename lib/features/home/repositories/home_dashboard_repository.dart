import '../models/home_dashboard_record.dart';
import '../models/learning_activity_snapshot.dart';
import '../models/my_course_record.dart';

abstract interface class HomeDashboardRepository {
  Future<HomeDashboardRecord> loadCachedDashboard();
  Future<List<MyCourseRecord>> loadCachedMyCourses();
  Future<void> clearCachedState();
  Future<HomeDashboardRecord> loadDashboard();
  Future<List<MyCourseRecord>> loadMyCourses();
  Future<LearningActivitySnapshot> loadLearningActivity();
  Future<LearningActivitySnapshot> recordLessonProgress({
    required String courseId,
    required String lessonId,
    required Duration position,
    required Duration totalDuration,
    required Duration watchedDelta,
    String courseTitle = '',
    int totalLessons = 0,
  });
}
