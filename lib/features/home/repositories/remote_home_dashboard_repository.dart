import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/home_dashboard_record.dart';
import '../models/java_development_course_data.dart';
import '../models/learning_activity_snapshot.dart';
import '../models/my_course_record.dart';
import '../models/product_design_course_data.dart';
import 'home_dashboard_repository.dart';
import 'local_home_dashboard_repository.dart';

class RemoteHomeDashboardRepository implements HomeDashboardRepository {
  RemoteHomeDashboardRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalHomeDashboardRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<HomeDashboardRecord> loadCachedDashboard() {
    return _localStore.loadDashboard();
  }

  @override
  Future<List<MyCourseRecord>> loadCachedMyCourses() {
    return _localStore.loadMyCourses();
  }

  @override
  Future<void> clearCachedState() {
    return _localStore.clearCachedState();
  }

  @override
  Future<HomeDashboardRecord> loadDashboard() async {
    final fallback = await _localStore.loadDashboard();
    final localActivity = await _localStore.loadLearningActivity();
    if (!await _hasAccessToken()) {
      return fallback;
    }

    try {
      final statsFuture = _apiClient
          .getJson(ApiEndpoints.user.stats)
          .then((statsBody) {
            return asMap(unwrapBody(statsBody, keys: const ['data', 'stats']));
          })
          .catchError((_) => <String, dynamic>{});
      final dashboardBody = await _apiClient.getJson(ApiEndpoints.user.dashboard);
      final statsMap = await statsFuture;

      final dashboardMap = asMap(
        unwrapBody(dashboardBody, keys: const ['data', 'dashboard']),
      );
      final mergedStatsMap = <String, dynamic>{
        ...dashboardMap,
        ...statsMap,
      };
      final meetupMap = readMap(dashboardMap, const ['meetup', 'community']);
      final learningCards = _parseLearningCards(
        readList(
          dashboardMap,
          const ['learning_cards', 'cards', 'categories', 'topics'],
        ),
      );
      final learningPlan = _parseLearningPlan(
        readList(dashboardMap, const ['learning_plan', 'plan', 'study_plan']),
      );
      final remoteLearnedTodaySeconds =
          _readPositiveInt(
            mergedStatsMap,
            const [
              'learned_today_seconds',
              'learnedTodaySeconds',
              'today_seconds',
              'todaySeconds',
            ],
            -1,
          ) >=
              0
          ? _readPositiveInt(
              mergedStatsMap,
              const [
                'learned_today_seconds',
                'learnedTodaySeconds',
                'today_seconds',
                'todaySeconds',
              ],
              0,
            )
          : _readPositiveInt(
                  mergedStatsMap,
                  const [
                    'learned_today_minutes',
                    'learnedTodayMinutes',
                    'today_minutes',
                    'todayMinutes',
                    'minutes_today',
                  ],
                  fallback.learnedTodayMinutes,
                ) *
                60;

      final dashboard = HomeDashboardRecord(
        learnedTodaySeconds: mathMax(
          remoteLearnedTodaySeconds,
          localActivity.watchedTodaySeconds,
        ),
        dailyGoalMinutes: _readPositiveInt(
          mergedStatsMap,
          const [
            'daily_goal_minutes',
            'dailyGoalMinutes',
            'goal_minutes',
            'goalMinutes',
            'study_goal_minutes',
          ],
          fallback.dailyGoalMinutes,
        ),
        totalHours: _readPositiveInt(
          mergedStatsMap,
          const ['total_hours', 'totalHours', 'hours_total', 'total_learning_hours'],
          fallback.totalHours,
        ),
        totalDays: _readPositiveInt(
          mergedStatsMap,
          const ['total_days', 'totalDays', 'days_total', 'streak_days'],
          fallback.totalDays,
        ),
        learningCards: learningCards.isEmpty
            ? fallback.learningCards
            : learningCards,
        learningPlan: _mergeLearningPlanWithLocalActivity(
          learningPlan.isEmpty ? fallback.learningPlan : learningPlan,
          localActivity,
        ),
        meetupTitle: readString(
          meetupMap,
          const ['title', 'heading'],
          fallback: readString(
            dashboardMap,
            const ['meetup_title', 'meetupTitle'],
            fallback: fallback.meetupTitle,
          ),
        ),
        meetupSubtitle: readString(
          meetupMap,
          const ['subtitle', 'description', 'body'],
          fallback: readString(
            dashboardMap,
            const ['meetup_subtitle', 'meetupSubtitle', 'meetup_description'],
            fallback: fallback.meetupSubtitle,
          ),
        ),
      );
      await _localStore.saveDashboardSnapshot(dashboard);
      return dashboard;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<List<MyCourseRecord>> loadMyCourses() async {
    final fallback = await _localStore.loadMyCourses();
    final localActivity = await _localStore.loadLearningActivity();
    if (!await _hasAccessToken()) {
      return fallback;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.myCourses);
      final payload = unwrapBody(
        body,
        keys: const ['data', 'courses', 'my_courses', 'myCourses'],
      );
      final list = payload is List
          ? payload
          : readList(
              asMap(body),
              const ['courses', 'my_courses', 'myCourses', 'data'],
            );

      final courses = list.map((item) {
        return _parseMyCourse(asMap(item));
      }).where((course) {
        return course.title.trim().isNotEmpty;
      }).toList();

      if (courses.isEmpty) {
        return fallback;
      }

      final mergedCourses = _mergeMyCoursesWithLocalActivity(
        courses,
        localActivity,
      );
      await _localStore.saveMyCoursesSnapshot(mergedCourses);
      return mergedCourses;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<LearningActivitySnapshot> loadLearningActivity() {
    return _localStore.loadLearningActivity();
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
    final snapshot = await _localStore.recordLessonProgress(
      courseId: courseId,
      lessonId: lessonId,
      position: position,
      totalDuration: totalDuration,
      watchedDelta: watchedDelta,
      courseTitle: courseTitle,
      totalLessons: totalLessons,
    );

    if (await _hasAccessToken()) {
      try {
        final progressPercent = totalDuration.inMilliseconds <= 0
            ? 0
            : ((position.inMilliseconds / totalDuration.inMilliseconds) * 100)
                .round()
                .clamp(0, 100);

        await _apiClient.postJson(
          ApiEndpoints.courses.lessonProgress(courseId, lessonId),
          body: <String, dynamic>{
            'position_seconds': position.inSeconds,
            'watched_seconds': position.inSeconds,
            'delta_seconds': watchedDelta.inSeconds,
            'duration_seconds': totalDuration.inSeconds,
            'progress_percent': progressPercent,
            'completed': progressPercent >= 90,
          },
        );
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await _expireSession();
        }
      } catch (_) {
        // Keep the local snapshot even if remote progress sync fails.
      }
    }

    return snapshot;
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
  }

  List<HomeLearningCardRecord> _parseLearningCards(List<dynamic> list) {
    return list.map((item) {
      final map = asMap(item);
      final count = readInt(
        map,
        const ['courses_count', 'course_count', 'count', 'total'],
        fallback: -1,
      );
      return HomeLearningCardRecord(
        title: readString(map, const ['title', 'name', 'label']),
        subtitle: readString(
          map,
          const ['subtitle', 'description'],
          fallback: count < 0 ? 'Courses' : '$count courses',
        ),
        buttonLabel: readString(
          map,
          const ['button_label', 'buttonLabel', 'cta', 'action_label'],
        ).trim().isEmpty
            ? null
            : readString(
                map,
                const ['button_label', 'buttonLabel', 'cta', 'action_label'],
              ),
        themeKey: readString(
          map,
          const ['theme', 'theme_key', 'themeKey', 'slug', 'color'],
        ),
      );
    }).where((item) {
      return item.title.trim().isNotEmpty;
    }).toList();
  }

  List<HomeLearningPlanRecord> _parseLearningPlan(List<dynamic> list) {
    return list.map((item) {
      final map = asMap(item);
      final progress = readInt(
        map,
        const ['progress', 'completed', 'completed_count', 'done_lessons'],
        fallback: 0,
      );
      final total = readInt(
        map,
        const ['total', 'total_count', 'lessons_count', 'total_lessons'],
        fallback: progress,
      );
      return HomeLearningPlanRecord(
        title: readString(map, const ['title', 'name', 'label']),
        progress: progress,
        total: total < progress ? progress : total,
        isDone: readBool(
          map,
          const ['is_done', 'isDone', 'completed_all'],
          fallback: total > 0 && progress >= total,
        ),
      );
    }).where((item) {
      return item.title.trim().isNotEmpty;
    }).toList();
  }

  List<HomeLearningPlanRecord> _mergeLearningPlanWithLocalActivity(
    List<HomeLearningPlanRecord> source,
    LearningActivitySnapshot localActivity,
  ) {
    return source.map((item) {
      final normalizedTitle = item.title.trim().toLowerCase();
      final isProductDesign = normalizedTitle.contains('product design');
      if (!isProductDesign) {
        return item;
      }

      final localProgress = localActivity.completedProductDesignLessonsCount;
      return HomeLearningPlanRecord(
        title: item.title,
        progress: mathMax(item.progress, localProgress),
        total: mathMax(item.total, productDesignLessons.length),
        isDone:
            item.isDone ||
            localProgress >= mathMax(item.total, productDesignLessons.length),
      );
    }).toList();
  }

  MyCourseRecord _parseMyCourse(Map<String, dynamic> root) {
    final course = readMap(root, const ['course']);
    final progress = readMap(root, const ['progress', 'stats']);
    final source = course.isEmpty ? root : course;
    final title = readString(
      source,
      const ['title', 'name'],
      fallback: readString(root, const ['title', 'name']),
    );
    final completedCount = _readPositiveInt(
      <String, dynamic>{...root, ...progress, ...source},
      const [
        'completed_lessons',
        'completedLessons',
        'completed_count',
        'completedCount',
        'done_lessons',
      ],
      0,
    );
    final lessons = readList(source, const ['lessons']);
    final totalCount = _readPositiveInt(
      <String, dynamic>{...root, ...progress, ...source},
      const [
        'lessons_count',
        'lesson_count',
        'lessonsCount',
        'lessonCount',
        'total_lessons',
        'totalLessons',
      ],
      lessons.length,
    );

    final courseId = readString(
      source,
      const ['id', 'course_id', 'slug'],
      fallback: readString(root, const ['course_id']),
    );

    if (ApiConfig.matchesProductDesignCourse(id: courseId, title: title)) {
      ApiConfig.resolveProductDesignCourse(id: courseId, title: title);
    }

    final isJavaDevelopment = matchesJavaDevelopmentCourse(
      id: courseId,
      title: title,
    );

    return MyCourseRecord(
      id: courseId,
      title: isJavaDevelopment ? javaDevelopmentCourseTitle : title,
      displayTitle: readString(
        source,
        const ['display_title', 'displayTitle'],
        fallback: _displayTitleFor(
          isJavaDevelopment ? javaDevelopmentCourseTitle : title,
        ),
      ),
      completedCount: completedCount,
      totalCount: isJavaDevelopment
          ? mathMax(
              totalCount < completedCount ? completedCount : totalCount,
              javaDevelopmentLessons.length,
            )
          : totalCount < completedCount
          ? completedCount
          : totalCount,
    );
  }

  List<MyCourseRecord> _mergeMyCoursesWithLocalActivity(
    List<MyCourseRecord> source,
    LearningActivitySnapshot localActivity,
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
          completedCount: mathMax(
            course.completedCount,
            localActivity.completedProductDesignLessonsCount,
          ),
          totalCount: mathMax(course.totalCount, productDesignLessons.length),
        );
      }

      final completedGenericCount = localActivity.completedGenericLessonsCountFor(
        courseId: course.id,
        title: course.title,
      );
      return MyCourseRecord(
        id: course.id,
        title: course.title,
        displayTitle: course.displayTitle,
        completedCount: mathMax(course.completedCount, completedGenericCount),
        totalCount: mathMax(course.totalCount, completedGenericCount),
      );
    }).toList();
  }

  int _readPositiveInt(
    Map<String, dynamic> map,
    List<String> keys,
    int fallback,
  ) {
    final value = readInt(map, keys, fallback: fallback);
    return value < 0 ? fallback : value;
  }

  String _displayTitleFor(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return title;
    }

    return '${words.first}\n${words.sublist(1).join(' ')}';
  }
}

int mathMax(int first, int second) => first >= second ? first : second;

