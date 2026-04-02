import '../models/course_catalog_data.dart';
import '../models/course_detail_record.dart';
import '../models/favourite_lesson_record.dart';

abstract interface class CourseCatalogRepository {
  Future<List<CourseCatalogItem>> loadCachedCourses();
  Future<List<String>> loadCachedCategories();
  Future<List<FavouriteLessonRecord>> loadCachedFavouriteLessons();
  Future<void> resetUserScopedState();
  Future<List<CourseCatalogItem>> loadCourses();
  Future<List<String>> loadCategories();
  Future<List<FavouriteLessonRecord>> loadFavouriteLessons();
  Future<CourseDetailRecord> loadCourseDetail(
    String courseId, {
    CourseCatalogItem? fallbackCourse,
  });
  Future<void> setCourseFavourite(
    String courseId, {
    required bool isFavourite,
  });
  Future<void> setLessonFavourite({
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
    required String durationLabel,
    required bool isFavourite,
  });
}
