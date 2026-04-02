import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/course_catalog_data.dart';
import '../models/course_detail_record.dart';
import '../models/favourite_lesson_record.dart';
import '../models/product_design_course_data.dart';
import '../repositories/course_catalog_repository.dart';

class CourseCatalogController extends GetxController {
  CourseCatalogController(this._repository);

  final CourseCatalogRepository _repository;

  List<CourseCatalogItem> _courses = const <CourseCatalogItem>[];
  List<String> _categories = const <String>[];
  List<FavouriteLessonRecord> _favouriteLessons = const <FavouriteLessonRecord>[];
  bool _isLoadingCatalog = false;
  bool _isLoadingFavourites = false;
  String _lastErrorMessage = '';

  List<CourseCatalogItem> get courses =>
      List<CourseCatalogItem>.unmodifiable(_courses);
  List<String> get categories => List<String>.unmodifiable(_categories);
  List<FavouriteLessonRecord> get favouriteLessons =>
      List<FavouriteLessonRecord>.unmodifiable(_favouriteLessons);
  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingFavourites => _isLoadingFavourites;
  String get lastErrorMessage => _lastErrorMessage;

  List<CourseCatalogItem> get featuredCourses {
    return _courses.where((course) => course.isPopular || course.isNew).toList();
  }

  List<String> get searchSuggestions {
    final suggestions = <String>[];

    for (final category in _categories) {
      if (suggestions.length >= 4) {
        break;
      }
      suggestions.add(category);
    }

    for (final course in _courses) {
      if (suggestions.length >= 6) {
        break;
      }
      if (!suggestions.contains(course.title)) {
        suggestions.add(course.title);
      }
    }

    return suggestions;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _hydrateFromCache();
    await refreshAll();
  }

  Future<void> _hydrateFromCache() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _repository.loadCachedCategories(),
      _repository.loadCachedCourses(),
      _repository.loadCachedFavouriteLessons(),
    ]);

    _categories = List<String>.from(results[0] as List);
    _courses = List<CourseCatalogItem>.from(results[1] as List);
    _favouriteLessons = List<FavouriteLessonRecord>.from(results[2] as List);
    update();
  }

  Future<void> refreshCatalog() async {
    if (_isLoadingCatalog) {
      return;
    }

    _isLoadingCatalog = true;
    _lastErrorMessage = '';
    update();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.loadCategories(),
        _repository.loadCourses(),
      ]);

      _categories = List<String>.from(results[0] as List);
      _courses = List<CourseCatalogItem>.from(results[1] as List);
    } catch (error) {
      _lastErrorMessage = error.toString();
    } finally {
      _isLoadingCatalog = false;
      update();
    }
  }

  Future<void> refreshFavourites() async {
    if (_isLoadingFavourites) {
      return;
    }

    _isLoadingFavourites = true;
    update();

    try {
      _favouriteLessons = await _repository.loadFavouriteLessons();
    } catch (error) {
      _lastErrorMessage = error.toString();
    } finally {
      _isLoadingFavourites = false;
      update();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      refreshCatalog(),
      refreshFavourites(),
    ]);
  }

  Future<void> resetForSignedOutUser() async {
    _courses = _courses.map((course) {
      return course.copyWith(isFavourite: false);
    }).toList();
    _favouriteLessons = const <FavouriteLessonRecord>[];
    _isLoadingCatalog = false;
    _isLoadingFavourites = false;
    _lastErrorMessage = '';
    await _repository.resetUserScopedState();
    update();
  }

  Future<CourseDetailRecord> loadCourseDetail(
    String courseId, {
    CourseCatalogItem? fallbackCourse,
  }) {
    return _repository.loadCourseDetail(courseId, fallbackCourse: fallbackCourse);
  }

  CourseCatalogItem? courseById(String courseId) {
    for (final course in _courses) {
      if (course.id == courseId) {
        return course;
      }
    }
    return null;
  }

  bool isCourseFavourite(String courseId) {
    final course = courseById(courseId);
    return course?.isFavourite ?? false;
  }

  bool isLessonFavourite(String lessonId) {
    return _favouriteLessons.any((lesson) => lesson.lessonId == lessonId);
  }

  Future<bool> setCourseFavourite(
    String courseId, {
    required bool isFavourite,
  }) async {
    final previousCourses = _courses;
    _courses = _courses.map((course) {
      if (course.id == courseId) {
        return course.copyWith(isFavourite: isFavourite);
      }
      return course;
    }).toList();
    update();

    try {
      await _repository.setCourseFavourite(
        courseId,
        isFavourite: isFavourite,
      );
      return true;
    } catch (error) {
      _courses = previousCourses;
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  Future<bool> setLessonFavourite({
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
    required String durationLabel,
    required bool isFavourite,
  }) async {
    final previousFavourites = _favouriteLessons;
    if (isFavourite) {
      final alreadyExists = _favouriteLessons.any(
        (lesson) => lesson.lessonId == lessonId,
      );
      if (!alreadyExists) {
        _favouriteLessons = <FavouriteLessonRecord>[
          FavouriteLessonRecord(
            id: 'favourite_$lessonId',
            lessonId: lessonId,
            courseId: courseId,
            courseTitle: courseTitle,
            title: lessonTitle,
            durationLabel: durationLabel,
          ),
          ..._favouriteLessons,
        ];
      }
    } else {
      _favouriteLessons = _favouriteLessons.where((lesson) {
        return lesson.lessonId != lessonId;
      }).toList();
    }
    update();

    try {
      await _repository.setLessonFavourite(
        courseId: courseId,
        courseTitle: courseTitle,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        durationLabel: durationLabel,
        isFavourite: isFavourite,
      );
      return true;
    } catch (error) {
      _favouriteLessons = previousFavourites;
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  int? lessonIndexForFavourite(FavouriteLessonRecord lesson) {
    for (var index = 0; index < productDesignLessons.length; index++) {
      final courseLesson = productDesignLessons[index];
      if (courseLesson.id == lesson.lessonId) {
        return index;
      }
    }

    if (ApiConfig.matchesProductDesignCourse(
      id: lesson.courseId,
      title: lesson.courseTitle,
    )) {
      for (var index = 0; index < productDesignLessons.length; index++) {
        final courseLesson = productDesignLessons[index];
        if (_normalizeKey(courseLesson.title) == _normalizeKey(lesson.title)) {
          return index;
        }
      }
    }

    return null;
  }

  String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
