import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/course_catalog_data.dart';
import '../models/course_purchase_record.dart';
import '../models/home_dashboard_record.dart';
import '../models/java_development_course_data.dart';
import '../models/learning_activity_snapshot.dart';
import '../models/my_course_record.dart';
import '../models/product_design_course_data.dart';
import 'local_course_purchase_repository.dart';
import 'local_product_design_purchase_repository.dart';
import 'home_dashboard_repository.dart';

class LocalHomeDashboardRepository implements HomeDashboardRepository {
  static const String _dashboardKey = 'home_dashboard_snapshot';
  static const String _myCoursesKey = 'home_my_courses_snapshot';
  static const String _watchedTodaySecondsPrefix =
      'learning_activity_watched_today_';
  static const String _completedProductLessonsKey =
      'learning_activity_completed_product_lessons';
  static const String _completedGenericLessonsPrefix =
      'learning_activity_completed_generic_lessons_';
  static const String _trackedWatchedCoursesKey =
      'learning_activity_tracked_watched_courses';
  static const String _productLessonPositionPrefix =
      'learning_activity_product_lesson_position_';
  static const String _genericLessonPositionPrefix =
      'learning_activity_generic_lesson_position_';

  LocalHomeDashboardRepository();

  final LocalCoursePurchaseRepository _coursePurchaseStore =
      LocalCoursePurchaseRepository();
  final LocalProductDesignPurchaseRepository _productDesignPurchaseStore =
      LocalProductDesignPurchaseRepository();
  HomeDashboardRecord? _dashboardCache;
  List<MyCourseRecord>? _myCoursesCache;

  @override
  Future<HomeDashboardRecord> loadCachedDashboard() => loadDashboard();

  @override
  Future<List<MyCourseRecord>> loadCachedMyCourses() => loadMyCourses();

  @override
  Future<HomeDashboardRecord> loadDashboard() async {
    final activity = await loadLearningActivity();
    if (_dashboardCache == null) {
      final preferences = await SharedPreferences.getInstance();
      final savedDashboard = preferences.getString(_dashboardKey);
      if (savedDashboard != null && savedDashboard.isNotEmpty) {
        try {
          _dashboardCache = _dashboardFromJson(
            Map<String, dynamic>.from(jsonDecode(savedDashboard) as Map),
          );
        } catch (_) {
          _dashboardCache = null;
        }
      }
    }

    return _mergeDashboardWithActivity(
      _dashboardCache ?? const HomeDashboardRecord.defaults(),
      activity,
    );
  }

  @override
  Future<List<MyCourseRecord>> loadMyCourses() async {
    final activity = await loadLearningActivity();
    final purchasedCourses = await _loadPurchasedCourses();
    if (_myCoursesCache == null) {
      final preferences = await SharedPreferences.getInstance();
      final savedMyCourses = preferences.getString(_myCoursesKey);
      if (savedMyCourses != null && savedMyCourses.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedMyCourses);
          if (decoded is List) {
            _myCoursesCache = decoded.map((item) {
              return _myCourseFromJson(Map<String, dynamic>.from(item as Map));
            }).toList();
          }
        } catch (_) {
          _myCoursesCache = null;
        }
      }
    }

    final mergedCourses = _mergePurchasedCoursesWithSavedCourses(
      _myCoursesCache ?? const <MyCourseRecord>[],
      purchasedCourses,
    );

    return _mergeMyCoursesWithActivity(
      mergedCourses,
      activity,
    );
  }

  Future<void> saveDashboardSnapshot(HomeDashboardRecord dashboard) async {
    _dashboardCache = dashboard;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _dashboardKey,
      jsonEncode(_dashboardToJson(dashboard)),
    );
  }

  Future<void> saveMyCoursesSnapshot(List<MyCourseRecord> courses) async {
    _myCoursesCache = List<MyCourseRecord>.from(courses);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _myCoursesKey,
      jsonEncode(_myCoursesCache!.map(_myCourseToJson).toList()),
    );
  }

  @override
  Future<void> clearCachedState() async {
    _dashboardCache = null;
    _myCoursesCache = null;

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_dashboardKey);
    await preferences.remove(_myCoursesKey);
    await preferences.remove(_completedProductLessonsKey);
    await preferences.remove(_trackedWatchedCoursesKey);

    final dynamicKeys = preferences.getKeys().where((key) {
      return key.startsWith(_watchedTodaySecondsPrefix) ||
          key.startsWith(_productLessonPositionPrefix) ||
          key.startsWith(_genericLessonPositionPrefix) ||
          key.startsWith(_completedGenericLessonsPrefix);
    }).toList();

    for (final key in dynamicKeys) {
      await preferences.remove(key);
    }
  }

  @override
  Future<LearningActivitySnapshot> loadLearningActivity() async {
    final preferences = await SharedPreferences.getInstance();
    final watchedTodaySeconds = preferences.getInt(
      '$_watchedTodaySecondsPrefix${_todayKey()}',
    );
    final completedGenericLessonIdsByCourse = <String, Set<String>>{};

    for (final key in preferences.getKeys()) {
      if (!key.startsWith(_completedGenericLessonsPrefix)) {
        continue;
      }

      final courseKey = key.substring(_completedGenericLessonsPrefix.length);
      if (courseKey.trim().isEmpty) {
        continue;
      }

      completedGenericLessonIdsByCourse[courseKey] =
          preferences.getStringList(key)?.toSet() ?? <String>{};
    }

    return LearningActivitySnapshot(
      watchedTodaySeconds: watchedTodaySeconds ?? 0,
      completedProductDesignLessonIds: preferences
          .getStringList(_completedProductLessonsKey)
          ?.toSet() ??
          <String>{},
      completedGenericLessonIdsByCourse: completedGenericLessonIdsByCourse,
    );
  }

  Future<List<MyCourseRecord>> loadTrackedWatchedCourses() async {
    final preferences = await SharedPreferences.getInstance();
    final trackedKeys = preferences.getStringList(_trackedWatchedCoursesKey)?.toSet() ??
        <String>{};
    if (trackedKeys.isEmpty) {
      return const <MyCourseRecord>[];
    }

    final courses = await loadMyCourses();
    return courses.where((course) {
      return trackedKeys.contains(_courseActivityKey(courseId: course.id, title: course.title));
    }).toList();
  }

  @override
  Future<LearningActivitySnapshot> recordLessonProgress({
    required String courseId,
    required String lessonId,
    required Duration position,
    required Duration totalDuration,
    required Duration watchedDelta,
    String courseTitle = '',
    int totalLessons = 0,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final todayKey = '$_watchedTodaySecondsPrefix${_todayKey()}';
    final watchedDeltaSeconds = math.max(0, watchedDelta.inSeconds);
    final currentTodaySeconds = preferences.getInt(todayKey) ?? 0;

    if (watchedDeltaSeconds > 0) {
      await preferences.setInt(todayKey, currentTodaySeconds + watchedDeltaSeconds);
    }

    if (ApiConfig.matchesProductDesignCourse(id: courseId, title: courseTitle)) {
      final positionKey = '$_productLessonPositionPrefix$lessonId';
      final currentPositionSeconds = preferences.getInt(positionKey) ?? 0;
      final nextPositionSeconds = math.max(currentPositionSeconds, position.inSeconds);
      await preferences.setInt(positionKey, nextPositionSeconds);

      if (_isLessonCompleted(nextPositionSeconds, totalDuration.inSeconds)) {
        final completedLessons = preferences
            .getStringList(_completedProductLessonsKey)
            ?.toSet() ??
            <String>{};
        if (!completedLessons.contains(lessonId)) {
          completedLessons.add(lessonId);
          await preferences.setStringList(
            _completedProductLessonsKey,
            completedLessons.toList()..sort(),
          );
        }
      }
    } else {
      final courseKey = _courseActivityKey(courseId: courseId, title: courseTitle);
      if (courseKey.isNotEmpty) {
        final positionKey = '$_genericLessonPositionPrefix${courseKey}_$lessonId';
        final currentPositionSeconds = preferences.getInt(positionKey) ?? 0;
        final nextPositionSeconds = math.max(currentPositionSeconds, position.inSeconds);
        await preferences.setInt(positionKey, nextPositionSeconds);

        final trackedCourses =
            preferences.getStringList(_trackedWatchedCoursesKey)?.toSet() ??
            <String>{};
        if (!trackedCourses.contains(courseKey)) {
          trackedCourses.add(courseKey);
          await preferences.setStringList(
            _trackedWatchedCoursesKey,
            trackedCourses.toList()..sort(),
          );
        }

        final completedLessonsKey = '$_completedGenericLessonsPrefix$courseKey';
        final completedLessons =
            preferences.getStringList(completedLessonsKey)?.toSet() ?? <String>{};
        if (_isLessonCompleted(nextPositionSeconds, totalDuration.inSeconds) &&
            !completedLessons.contains(lessonId)) {
          completedLessons.add(lessonId);
          await preferences.setStringList(
            completedLessonsKey,
            completedLessons.toList()..sort(),
          );
        }

        if (courseTitle.trim().isNotEmpty) {
          await _upsertWatchedGenericCourse(
            courseId: courseId,
            courseTitle: courseTitle,
            totalLessons: totalLessons,
            completedCount: completedLessons.length,
          );
        }
      }
    }

    return loadLearningActivity();
  }

  bool _isLessonCompleted(int positionSeconds, int totalSeconds) {
    if (positionSeconds <= 0 || totalSeconds <= 0) {
      return false;
    }

    final completionThreshold = math.max(
      (totalSeconds * 0.9).round(),
      totalSeconds - 15,
    );
    return positionSeconds >= completionThreshold;
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  HomeDashboardRecord _mergeDashboardWithActivity(
    HomeDashboardRecord base,
    LearningActivitySnapshot activity,
  ) {
    return HomeDashboardRecord(
      learnedTodaySeconds: math.max(
        base.learnedTodaySeconds,
        activity.watchedTodaySeconds,
      ),
      dailyGoalMinutes: base.dailyGoalMinutes,
      totalHours: base.totalHours,
      totalDays: base.totalDays,
      learningCards: base.learningCards,
      learningPlan: base.learningPlan.map((item) {
        final isProductDesign = item.title.toLowerCase().contains('product design');
        if (!isProductDesign) {
          return item;
        }

        final total = math.max(item.total, productDesignLessons.length);
        final progress = math.max(
          item.progress,
          activity.completedProductDesignLessonsCount,
        );
        return HomeLearningPlanRecord(
          title: item.title,
          progress: progress,
          total: total,
          isDone: item.isDone || progress >= total,
        );
      }).toList(),
      meetupTitle: base.meetupTitle,
      meetupSubtitle: base.meetupSubtitle,
    );
  }

  List<MyCourseRecord> _mergeMyCoursesWithActivity(
    List<MyCourseRecord> source,
    LearningActivitySnapshot activity,
  ) {
    return source.map((course) {
      final isProductDesign = ApiConfig.matchesProductDesignCourse(
        id: course.id,
        title: course.title,
      );
      if (isProductDesign) {
        return MyCourseRecord(
          id: course.id,
          title: course.title,
          displayTitle: course.displayTitle,
          completedCount: math.max(
            course.completedCount,
            activity.completedProductDesignLessonsCount,
          ),
          totalCount: math.max(course.totalCount, productDesignLessons.length),
        );
      }

      final completedGenericCount = activity.completedGenericLessonsCountFor(
        courseId: course.id,
        title: course.title,
      );
      return MyCourseRecord(
        id: course.id,
        title: course.title,
        displayTitle: course.displayTitle,
        completedCount: math.max(course.completedCount, completedGenericCount),
        totalCount: math.max(course.totalCount, completedGenericCount),
      );
    }).toList();
  }

  Future<void> _upsertWatchedGenericCourse({
    required String courseId,
    required String courseTitle,
    required int totalLessons,
    required int completedCount,
  }) async {
    final courses = await loadMyCourses();
    final index = courses.indexWhere((course) {
      if (course.id.trim().isNotEmpty &&
          course.id.trim().toLowerCase() == courseId.trim().toLowerCase()) {
        return true;
      }

      return _normalizeKey(course.title) == _normalizeKey(courseTitle);
    });

    final nextRecord = MyCourseRecord(
      id: courseId,
      title: courseTitle,
      displayTitle: _displayTitleFor(courseTitle),
      completedCount: completedCount,
      totalCount: math.max(totalLessons, completedCount),
    );

    if (index < 0) {
      return;
    }

    final existing = courses[index];
    final updatedCourses = List<MyCourseRecord>.from(courses);
    updatedCourses[index] = MyCourseRecord(
      id: existing.id.isEmpty ? nextRecord.id : existing.id,
      title: existing.title.isEmpty ? nextRecord.title : existing.title,
      displayTitle: existing.displayTitle.isEmpty
          ? nextRecord.displayTitle
          : existing.displayTitle,
      completedCount: math.max(existing.completedCount, completedCount),
      totalCount: math.max(existing.totalCount, nextRecord.totalCount),
    );
    await saveMyCoursesSnapshot(updatedCourses);
  }

  Future<List<MyCourseRecord>> _loadPurchasedCourses() async {
    final genericPurchases = await _coursePurchaseStore.loadPurchases();
    final productDesignPurchase = await _productDesignPurchaseStore.loadPurchase();
    final purchasedCourses = <MyCourseRecord>[];

    if (productDesignPurchase.isPurchased) {
      purchasedCourses.add(
        MyCourseRecord(
          id: ApiConfig.productDesignCourseId,
          title: productDesignCourseTitle,
          displayTitle: 'Product\nDesign v1.0',
          completedCount: 0,
          totalCount: productDesignLessons.length,
        ),
      );
    }

    for (final purchase in genericPurchases) {
      if (!purchase.isPurchased) {
        continue;
      }

      final record = _myCourseFromPurchase(purchase);
      if (record == null) {
        continue;
      }

      final alreadyExists = purchasedCourses.any((course) {
        return _courseActivityKey(courseId: course.id, title: course.title) ==
            _courseActivityKey(courseId: record.id, title: record.title);
      });
      if (!alreadyExists) {
        purchasedCourses.add(record);
      }
    }

    return purchasedCourses;
  }

  List<MyCourseRecord> _mergePurchasedCoursesWithSavedCourses(
    List<MyCourseRecord> savedCourses,
    List<MyCourseRecord> purchasedCourses,
  ) {
    if (purchasedCourses.isEmpty) {
      return const <MyCourseRecord>[];
    }
    if (savedCourses.isEmpty) {
      return purchasedCourses;
    }

    final purchasedKeys = purchasedCourses.map((course) {
      return _courseActivityKey(courseId: course.id, title: course.title);
    }).toSet();

    final mergedCourses = savedCourses.where((course) {
      return purchasedKeys.contains(
        _courseActivityKey(courseId: course.id, title: course.title),
      );
    }).toList();

    for (final purchasedCourse in purchasedCourses) {
      final existingIndex = mergedCourses.indexWhere((course) {
        return _courseActivityKey(courseId: course.id, title: course.title) ==
            _courseActivityKey(
              courseId: purchasedCourse.id,
              title: purchasedCourse.title,
            );
      });

      if (existingIndex < 0) {
        mergedCourses.add(purchasedCourse);
        continue;
      }

      final existing = mergedCourses[existingIndex];
      mergedCourses[existingIndex] = MyCourseRecord(
        id: existing.id.isEmpty ? purchasedCourse.id : existing.id,
        title: existing.title.isEmpty ? purchasedCourse.title : existing.title,
        displayTitle: existing.displayTitle.isEmpty
            ? purchasedCourse.displayTitle
            : existing.displayTitle,
        completedCount: math.max(
          existing.completedCount,
          purchasedCourse.completedCount,
        ),
        totalCount: math.max(existing.totalCount, purchasedCourse.totalCount),
      );
    }

    return mergedCourses;
  }

  MyCourseRecord? _myCourseFromPurchase(CoursePurchaseRecord purchase) {
    final courseId = purchase.courseId.trim();
    final courseTitle = purchase.courseTitle.trim();
    final normalizedTitle = courseTitle.isEmpty ? 'Course' : courseTitle;

    if (ApiConfig.matchesProductDesignCourse(id: courseId, title: courseTitle)) {
      return MyCourseRecord(
        id: courseId.isEmpty ? ApiConfig.productDesignCourseId : courseId,
        title: productDesignCourseTitle,
        displayTitle: 'Product\nDesign v1.0',
        completedCount: 0,
        totalCount: productDesignLessons.length,
      );
    }

    if (matchesJavaDevelopmentCourse(id: courseId, title: courseTitle)) {
      return MyCourseRecord(
        id: javaDevelopmentCourseId,
        title: javaDevelopmentCourseTitle,
        displayTitle: 'Java\nDevelopment',
        completedCount: 0,
        totalCount: javaDevelopmentLessons.length,
      );
    }

    final catalogItem = courseCatalogItems.firstWhere(
      (item) {
        final itemId = item.id.trim().toLowerCase();
        final itemTitle = _normalizeKey(item.title);
        return (courseId.isNotEmpty && itemId == courseId.toLowerCase()) ||
            (courseTitle.isNotEmpty && itemTitle == _normalizeKey(courseTitle));
      },
      orElse: () => CourseCatalogItem(
        id: courseId,
        title: normalizedTitle,
        teacher: '',
        price: 0,
        durationHours: 0,
        category: 'General',
        thumbnailColor: const Color(0xFFD8F0FF),
      ),
    );

    final resolvedTitle = catalogItem.title.trim().isEmpty
        ? normalizedTitle
        : catalogItem.title;

    return MyCourseRecord(
      id: catalogItem.id.trim().isEmpty ? courseId : catalogItem.id,
      title: resolvedTitle,
      displayTitle: _displayTitleFor(resolvedTitle),
      completedCount: 0,
      totalCount: catalogItem.lessonCount,
    );
  }

  Map<String, dynamic> _dashboardToJson(HomeDashboardRecord dashboard) {
    return <String, dynamic>{
      'learned_today_seconds': dashboard.learnedTodaySeconds,
      'daily_goal_minutes': dashboard.dailyGoalMinutes,
      'total_hours': dashboard.totalHours,
      'total_days': dashboard.totalDays,
      'learning_cards': dashboard.learningCards.map((card) {
        return <String, dynamic>{
          'title': card.title,
          'subtitle': card.subtitle,
          'button_label': card.buttonLabel,
          'theme_key': card.themeKey,
        };
      }).toList(),
      'learning_plan': dashboard.learningPlan.map((item) {
        return <String, dynamic>{
          'title': item.title,
          'progress': item.progress,
          'total': item.total,
          'is_done': item.isDone,
        };
      }).toList(),
      'meetup_title': dashboard.meetupTitle,
      'meetup_subtitle': dashboard.meetupSubtitle,
    };
  }

  HomeDashboardRecord _dashboardFromJson(Map<String, dynamic> json) {
    final learningCards = ((json['learning_cards'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((item) {
          return HomeLearningCardRecord(
            title: (item['title'] ?? '').toString(),
            subtitle: (item['subtitle'] ?? '').toString(),
            buttonLabel: item['button_label']?.toString(),
            themeKey: (item['theme_key'] ?? '').toString(),
          );
        }).where((item) => item.title.trim().isNotEmpty).toList();
    final learningPlan = ((json['learning_plan'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((item) {
          return HomeLearningPlanRecord(
            title: (item['title'] ?? '').toString(),
            progress: (item['progress'] as num?)?.round() ?? 0,
            total: (item['total'] as num?)?.round() ?? 0,
            isDone: item['is_done'] == true,
          );
        }).where((item) => item.title.trim().isNotEmpty).toList();

    return HomeDashboardRecord(
      learnedTodaySeconds: (json['learned_today_seconds'] as num?)?.round() ?? 0,
      dailyGoalMinutes: (json['daily_goal_minutes'] as num?)?.round() ?? 60,
      totalHours: (json['total_hours'] as num?)?.round() ?? 468,
      totalDays: (json['total_days'] as num?)?.round() ?? 554,
      learningCards: learningCards.isEmpty
          ? const HomeDashboardRecord.defaults().learningCards
          : learningCards,
      learningPlan: learningPlan.isEmpty
          ? const HomeDashboardRecord.defaults().learningPlan
          : learningPlan,
      meetupTitle: (json['meetup_title'] ?? 'Meetup').toString(),
      meetupSubtitle:
          (json['meetup_subtitle'] ??
                  'Off-line exchange of learning experiences')
              .toString(),
    );
  }

  Map<String, dynamic> _myCourseToJson(MyCourseRecord course) {
    return <String, dynamic>{
      'id': course.id,
      'title': course.title,
      'display_title': course.displayTitle,
      'completed_count': course.completedCount,
      'total_count': course.totalCount,
    };
  }

  MyCourseRecord _myCourseFromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final isJavaDevelopment = matchesJavaDevelopmentCourse(id: id, title: title);
    final completedCount = (json['completed_count'] as num?)?.round() ?? 0;
    final totalCount = (json['total_count'] as num?)?.round() ?? 0;

    return MyCourseRecord(
      id: id,
      title: isJavaDevelopment ? javaDevelopmentCourseTitle : title,
      displayTitle: isJavaDevelopment
          ? 'Java\nDevelopment'
          : (json['display_title'] ?? '').toString(),
      completedCount: isJavaDevelopment
          ? math.min(completedCount, javaDevelopmentLessons.length)
          : completedCount,
      totalCount: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : totalCount,
    );
  }

  String _displayTitleFor(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return title;
    }

    return '${words.first}\n${words.sublist(1).join(' ')}';
  }

  String _courseActivityKey({
    required String courseId,
    String title = '',
  }) {
    final normalizedId = _normalizeKey(courseId);
    if (normalizedId.isNotEmpty) {
      return normalizedId;
    }

    return _normalizeKey(title);
  }

  String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
