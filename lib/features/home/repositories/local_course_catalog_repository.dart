import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/course_catalog_data.dart';
import '../models/course_detail_record.dart';
import '../models/course_price_display.dart';
import '../models/favourite_lesson_record.dart';
import '../models/java_development_course_data.dart';
import '../models/product_design_course_data.dart';
import 'course_catalog_repository.dart';

class LocalCourseCatalogRepository implements CourseCatalogRepository {
  static const List<int> _defaultFavouriteLessonIndexes = <int>[0, 1, 5, 7];
  static const int _genericFreePreviewCount = 2;
  static const String _coursesKey = 'course_catalog_courses';
  static const String _categoriesKey = 'course_catalog_categories';
  static const String _favouritesKey = 'course_catalog_favourites';

  List<CourseCatalogItem>? _coursesCache;
  List<String>? _categoriesCache;
  List<FavouriteLessonRecord>? _favouritesCache;

  @override
  Future<List<CourseCatalogItem>> loadCachedCourses() => loadCourses();

  @override
  Future<List<String>> loadCachedCategories() => loadCategories();

  @override
  Future<List<FavouriteLessonRecord>> loadCachedFavouriteLessons() =>
      loadFavouriteLessons();

  @override
  Future<List<CourseCatalogItem>> loadCourses() async {
    if (_coursesCache != null) {
      return List<CourseCatalogItem>.from(_coursesCache!);
    }

    final preferences = await SharedPreferences.getInstance();
    final savedCourses = preferences.getString(_coursesKey);
    if (savedCourses != null && savedCourses.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedCourses);
        if (decoded is List) {
          _coursesCache = decoded.map((item) {
            return _courseFromJson(Map<String, dynamic>.from(item as Map));
          }).toList();
        }
      } catch (_) {
        _coursesCache = null;
      }
    }

    _coursesCache ??= List<CourseCatalogItem>.from(courseCatalogItems);
    return List<CourseCatalogItem>.from(_coursesCache!);
  }

  @override
  Future<List<String>> loadCategories() async {
    if (_categoriesCache != null) {
      return List<String>.from(_categoriesCache!);
    }

    final preferences = await SharedPreferences.getInstance();
    final savedCategories = preferences.getStringList(_categoriesKey);
    if (savedCategories != null && savedCategories.isNotEmpty) {
      _categoriesCache = List<String>.from(savedCategories);
    }

    _categoriesCache ??= List<String>.from(courseFilterCategories);
    return List<String>.from(_categoriesCache!);
  }

  @override
  Future<List<FavouriteLessonRecord>> loadFavouriteLessons() async {
    if (_favouritesCache != null) {
      return List<FavouriteLessonRecord>.from(_favouritesCache!);
    }

    final preferences = await SharedPreferences.getInstance();
    final savedFavourites = preferences.getString(_favouritesKey);
    if (savedFavourites != null && savedFavourites.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedFavourites);
        if (decoded is List) {
          _favouritesCache = decoded.map((item) {
            return _favouriteFromJson(Map<String, dynamic>.from(item as Map));
          }).toList();
        }
      } catch (_) {
        _favouritesCache = null;
      }
    }

    _favouritesCache ??= _defaultFavouriteLessonIndexes.map((lessonIndex) {
      final lesson = productDesignLessons[lessonIndex];
      return FavouriteLessonRecord(
        id: 'favourite_${lesson.id}',
        lessonId: lesson.id,
        courseId: ApiConfig.productDesignCourseId,
        courseTitle: productDesignCourseTitle,
        title: lesson.title,
        durationLabel: lesson.fallbackDurationLabel,
      );
    }).toList();
    return List<FavouriteLessonRecord>.from(_favouritesCache!);
  }

  Future<void> saveCoursesSnapshot(List<CourseCatalogItem> courses) async {
    _coursesCache = List<CourseCatalogItem>.from(courses);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _coursesKey,
      jsonEncode(_coursesCache!.map(_courseToJson).toList()),
    );
  }

  Future<void> saveCategoriesSnapshot(List<String> categories) async {
    _categoriesCache = List<String>.from(categories);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_categoriesKey, _categoriesCache!);
  }

  Future<void> saveFavouriteLessonsSnapshot(
    List<FavouriteLessonRecord> favourites,
  ) async {
    _favouritesCache = List<FavouriteLessonRecord>.from(favourites);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _favouritesKey,
      jsonEncode(_favouritesCache!.map(_favouriteToJson).toList()),
    );
  }

  @override
  Future<void> resetUserScopedState() async {
    final courses = await loadCourses();
    await saveCoursesSnapshot(
      courses.map((course) => course.copyWith(isFavourite: false)).toList(),
    );
    await saveFavouriteLessonsSnapshot(const <FavouriteLessonRecord>[]);
  }

  @override
  Future<CourseDetailRecord> loadCourseDetail(
    String courseId, {
    CourseCatalogItem? fallbackCourse,
  }) async {
    final courses = await loadCourses();
    final course =
        fallbackCourse ??
        courses.firstWhere(
          (item) => item.id == courseId,
          orElse: () => CourseCatalogItem(
            id: courseId,
            title: 'Course',
            teacher: 'Course instructor',
            price: 0,
            durationHours: 0,
            category: 'General',
            thumbnailColor: const Color(0xFFD8F0FF),
            lessonCount: 0,
          ),
        );

    if (ApiConfig.matchesProductDesignCourse(
      id: courseId,
      title: course.title,
    )) {
      return CourseDetailRecord(
        id: course.id,
        title: productDesignCourseTitle,
        teacher: course.teacher,
        price: productDesignCoursePriceValue.round(),
        durationHours: 6,
        category: course.category,
        lessonCount: productDesignLessons.length,
        description: productDesignCourseDescription,
        isPopular: course.isPopular,
        isNew: course.isNew,
        isFavourite: course.isFavourite,
        isPurchased: true,
        lessons: productDesignLessons.map((lesson) {
          return CourseLessonRecord(
            id: lesson.id,
            title: lesson.title,
            durationLabel: lesson.fallbackDurationLabel,
          );
        }).toList(),
      );
    }

    if (matchesJavaDevelopmentCourse(id: courseId, title: course.title)) {
      final isPurchased = course.price <= 0;
      // Java Development is bundled locally in the app, so its lesson list and
      // asset paths come from java_development_course_data.dart instead of an
      // API response.
      return CourseDetailRecord(
        id: course.id,
        title: javaDevelopmentCourseTitle,
        teacher: course.teacher,
        price: normalizeCoursePrice(course.price),
        durationHours: javaDevelopmentCourseDurationHours,
        category: course.category,
        lessonCount: javaDevelopmentLessons.length,
        description: course.shortDescription.isEmpty
            ? javaDevelopmentCourseDescription
            : course.shortDescription,
        isPopular: course.isPopular,
        isNew: course.isNew,
        isFavourite: course.isFavourite,
        isPurchased: isPurchased,
        lessons: javaDevelopmentLessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          return CourseLessonRecord(
            id: lesson.id,
            title: lesson.title,
            durationLabel: lesson.fallbackDurationLabel,
            videoUrl: lesson.assetPath,
            // Paid generic courses keep the first two lessons open as previews.
            isLocked: !isPurchased && index >= _genericFreePreviewCount,
          );
        }).toList(),
      );
    }

    final isPurchased = course.price <= 0;
    final lessons = List<CourseLessonRecord>.generate(course.lessonCount, (index) {
      return CourseLessonRecord(
        id: '${course.id}_lesson_${index + 1}',
        title: 'Lesson ${index + 1}',
        durationLabel: 'Video lesson',
        isLocked: !isPurchased && index >= _genericFreePreviewCount,
      );
    });

    return CourseDetailRecord(
      id: course.id,
      title: course.title,
      teacher: course.teacher,
      price: normalizeCoursePrice(course.price),
      durationHours: course.durationHours,
      category: course.category,
      lessonCount: course.lessonCount,
      description: course.shortDescription,
      isPopular: course.isPopular,
      isNew: course.isNew,
      isFavourite: course.isFavourite,
      isPurchased: isPurchased,
      lessons: lessons,
    );
  }

  @override
  Future<void> setCourseFavourite(
    String courseId, {
    required bool isFavourite,
  }) async {
    final courses = await loadCourses();
    _coursesCache = courses.map((course) {
      if (course.id == courseId) {
        return course.copyWith(isFavourite: isFavourite);
      }
      return course;
    }).toList();
    await saveCoursesSnapshot(_coursesCache!);
  }

  @override
  Future<void> setLessonFavourite({
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
    required String durationLabel,
    required bool isFavourite,
  }) async {
    final currentFavourites = await loadFavouriteLessons();
    final exists = currentFavourites.any((lesson) => lesson.lessonId == lessonId);

    if (isFavourite && !exists) {
      _favouritesCache = <FavouriteLessonRecord>[
        FavouriteLessonRecord(
          id: 'favourite_$lessonId',
          lessonId: lessonId,
          courseId: courseId,
          courseTitle: courseTitle,
          title: lessonTitle,
          durationLabel: durationLabel,
        ),
        ...currentFavourites,
      ];
      await saveFavouriteLessonsSnapshot(_favouritesCache!);
      return;
    }

    if (!isFavourite && exists) {
      _favouritesCache = currentFavourites.where((lesson) {
        return lesson.lessonId != lessonId;
      }).toList();
      await saveFavouriteLessonsSnapshot(_favouritesCache!);
    }
  }

  Map<String, dynamic> _courseToJson(CourseCatalogItem course) {
    return <String, dynamic>{
      'id': course.id,
      'title': course.title,
      'teacher': course.teacher,
      'price': normalizeCoursePrice(course.price),
      'duration_hours': course.durationHours,
      'category': course.category,
      'thumbnail_color': course.thumbnailColor.toARGB32(),
      'lesson_count': course.lessonCount,
      'short_description': course.shortDescription,
      'is_popular': course.isPopular,
      'is_new': course.isNew,
      'is_favourite': course.isFavourite,
      'opens_product_detail': course.opensProductDetail,
    };
  }

  CourseCatalogItem _courseFromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final isProductDesign = ApiConfig.matchesProductDesignCourse(
      id: id,
      title: title,
    );
    final isJavaDevelopment = matchesJavaDevelopmentCourse(
      id: id,
      title: title,
    );

    return CourseCatalogItem(
      id: id,
      title: isJavaDevelopment ? javaDevelopmentCourseTitle : title,
      teacher: (json['teacher'] ?? '').toString(),
      price: isProductDesign
          ? productDesignCoursePriceValue.round()
          : normalizeCoursePrice((json['price'] as num?)?.round() ?? 0),
      durationHours: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : (json['duration_hours'] as num?)?.round() ?? 0,
      category: (json['category'] ?? '').toString(),
      thumbnailColor: Color((json['thumbnail_color'] as num?)?.toInt() ?? 0xFFD8F0FF),
      lessonCount: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : (json['lesson_count'] as num?)?.round() ?? 0,
      shortDescription: isJavaDevelopment
          ? ((json['short_description'] ?? '').toString().trim().isEmpty
                ? javaDevelopmentCourseDescription
                : (json['short_description'] ?? '').toString())
          : (json['short_description'] ?? '').toString(),
      isPopular: json['is_popular'] == true,
      isNew: json['is_new'] == true,
      isFavourite: json['is_favourite'] == true,
      opensProductDetail: json['opens_product_detail'] == true || isProductDesign,
    );
  }

  Map<String, dynamic> _favouriteToJson(FavouriteLessonRecord lesson) {
    return <String, dynamic>{
      'id': lesson.id,
      'lesson_id': lesson.lessonId,
      'course_id': lesson.courseId,
      'course_title': lesson.courseTitle,
      'title': lesson.title,
      'duration_label': lesson.durationLabel,
    };
  }

  FavouriteLessonRecord _favouriteFromJson(Map<String, dynamic> json) {
    return FavouriteLessonRecord(
      id: (json['id'] ?? '').toString(),
      lessonId: (json['lesson_id'] ?? '').toString(),
      courseId: (json['course_id'] ?? '').toString(),
      courseTitle: (json['course_title'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      durationLabel: (json['duration_label'] ?? '').toString(),
    );
  }
}
