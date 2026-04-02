import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/home_dashboard_record.dart';
import '../models/learning_activity_snapshot.dart';
import '../models/my_course_record.dart';
import '../models/product_design_course_data.dart';
import '../repositories/home_dashboard_repository.dart';

class HomeDashboardController extends GetxController {
  HomeDashboardController(this._repository);

  final HomeDashboardRepository _repository;

  HomeDashboardRecord _dashboard = const HomeDashboardRecord.defaults();
  List<MyCourseRecord> _myCourses = const <MyCourseRecord>[];
  bool _isLoadingDashboard = false;
  bool _isLoadingMyCourses = false;
  String _lastErrorMessage = '';
  LearningActivitySnapshot _activity = const LearningActivitySnapshot.empty();

  HomeDashboardRecord get dashboard => _dashboard;
  List<MyCourseRecord> get myCourses => List<MyCourseRecord>.unmodifiable(_myCourses);
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingMyCourses => _isLoadingMyCourses;
  String get lastErrorMessage => _lastErrorMessage;

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
      _repository.loadCachedDashboard(),
      _repository.loadCachedMyCourses(),
      _repository.loadLearningActivity(),
    ]);

    _dashboard = results[0] as HomeDashboardRecord;
    _myCourses = List<MyCourseRecord>.from(results[1] as List);
    _activity = results[2] as LearningActivitySnapshot;
    update();
  }

  Future<void> refreshDashboard() async {
    if (_isLoadingDashboard) {
      return;
    }

    _isLoadingDashboard = true;
    _lastErrorMessage = '';
    update();

    try {
      _dashboard = await _repository.loadDashboard();
      _activity = await _repository.loadLearningActivity();
    } catch (error) {
      _lastErrorMessage = error.toString();
    } finally {
      _isLoadingDashboard = false;
      update();
    }
  }

  Future<void> refreshMyCourses() async {
    if (_isLoadingMyCourses) {
      return;
    }

    _isLoadingMyCourses = true;
    update();

    try {
      _myCourses = await _repository.loadMyCourses();
      _activity = await _repository.loadLearningActivity();
    } catch (error) {
      _lastErrorMessage = error.toString();
    } finally {
      _isLoadingMyCourses = false;
      update();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      refreshDashboard(),
      refreshMyCourses(),
    ]);
  }

  Future<void> resetForSignedOutUser() async {
    _dashboard = const HomeDashboardRecord.defaults();
    _myCourses = const <MyCourseRecord>[];
    _activity = const LearningActivitySnapshot.empty();
    _isLoadingDashboard = false;
    _isLoadingMyCourses = false;
    _lastErrorMessage = '';
    await _repository.clearCachedState();
    update();
  }

  Future<void> recordLessonProgress({
    required String courseId,
    required String lessonId,
    required Duration position,
    required Duration totalDuration,
    required Duration watchedDelta,
    String courseTitle = '',
    int totalLessons = 0,
  }) async {
    _activity = await _repository.recordLessonProgress(
      courseId: courseId,
      lessonId: lessonId,
      position: position,
      totalDuration: totalDuration,
      watchedDelta: watchedDelta,
      courseTitle: courseTitle,
      totalLessons: totalLessons,
    );
    _upsertWatchedCourse(
      courseId: courseId,
      courseTitle: courseTitle,
      totalLessons: totalLessons,
    );
    _applyLearningActivitySnapshot();
    update();
  }

  void _applyLearningActivitySnapshot() {
    _dashboard = HomeDashboardRecord(
      learnedTodaySeconds: _activity.watchedTodaySeconds > _dashboard.learnedTodaySeconds
          ? _activity.watchedTodaySeconds
          : _dashboard.learnedTodaySeconds,
      dailyGoalMinutes: _dashboard.dailyGoalMinutes,
      totalHours: _dashboard.totalHours,
      totalDays: _dashboard.totalDays,
      learningCards: _dashboard.learningCards,
      learningPlan: _dashboard.learningPlan.map((item) {
        final isProductDesign = item.title.toLowerCase().contains('product design');
        if (!isProductDesign) {
          return item;
        }

        return HomeLearningPlanRecord(
          title: item.title,
          progress: _activity.completedProductDesignLessonsCount > item.progress
              ? _activity.completedProductDesignLessonsCount
              : item.progress,
          total: item.total > productDesignLessons.length
              ? item.total
              : productDesignLessons.length,
          isDone:
              item.isDone ||
              _activity.completedProductDesignLessonsCount >=
                  productDesignLessons.length,
        );
      }).toList(),
      meetupTitle: _dashboard.meetupTitle,
      meetupSubtitle: _dashboard.meetupSubtitle,
    );

    _myCourses = _myCourses.map((course) {
      final isProductDesign = ApiConfig.matchesProductDesignCourse(
        id: course.id,
        title: course.title,
      );
      if (isProductDesign) {
        return MyCourseRecord(
          id: course.id,
          title: course.title,
          displayTitle: course.displayTitle,
          completedCount:
              _activity.completedProductDesignLessonsCount > course.completedCount
              ? _activity.completedProductDesignLessonsCount
              : course.completedCount,
          totalCount: course.totalCount > productDesignLessons.length
              ? course.totalCount
              : productDesignLessons.length,
        );
      }

      final completedGenericCount = _activity.completedGenericLessonsCountFor(
        courseId: course.id,
        title: course.title,
      );
      return MyCourseRecord(
        id: course.id,
        title: course.title,
        displayTitle: course.displayTitle,
        completedCount: completedGenericCount > course.completedCount
            ? completedGenericCount
            : course.completedCount,
        totalCount: course.totalCount > completedGenericCount
            ? course.totalCount
            : completedGenericCount,
      );
    }).toList();
  }

  void _upsertWatchedCourse({
    required String courseId,
    required String courseTitle,
    required int totalLessons,
  }) {
    final normalizedTitle = courseTitle.trim();
    if (normalizedTitle.isEmpty) {
      return;
    }

    final completedCount = ApiConfig.matchesProductDesignCourse(
      id: courseId,
      title: courseTitle,
    )
        ? _activity.completedProductDesignLessonsCount
        : _activity.completedGenericLessonsCountFor(
            courseId: courseId,
            title: courseTitle,
          );

    final resolvedTotalCount = totalLessons > completedCount
        ? totalLessons
        : completedCount;
    final existingIndex = _myCourses.indexWhere((course) {
      if (course.id.trim().isNotEmpty &&
          course.id.trim().toLowerCase() == courseId.trim().toLowerCase()) {
        return true;
      }

      return _normalizeCourseKey(course.title) == _normalizeCourseKey(courseTitle);
    });

    final nextRecord = MyCourseRecord(
      id: courseId,
      title: normalizedTitle,
      displayTitle: _displayTitleFor(normalizedTitle),
      completedCount: completedCount,
      totalCount: resolvedTotalCount,
    );

    if (existingIndex < 0) {
      return;
    }

    final existing = _myCourses[existingIndex];
    _myCourses[existingIndex] = MyCourseRecord(
      id: existing.id.isEmpty ? nextRecord.id : existing.id,
      title: existing.title.isEmpty ? nextRecord.title : existing.title,
      displayTitle: existing.displayTitle.isEmpty
          ? nextRecord.displayTitle
          : existing.displayTitle,
      completedCount: completedCount > existing.completedCount
          ? completedCount
          : existing.completedCount,
      totalCount: resolvedTotalCount > existing.totalCount
          ? resolvedTotalCount
          : existing.totalCount,
    );
  }

  String _displayTitleFor(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return title;
    }

    return '${words.first}\n${words.sublist(1).join(' ')}';
  }

  String _normalizeCourseKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
