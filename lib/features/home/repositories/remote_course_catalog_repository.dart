import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/course_catalog_data.dart';
import '../models/course_detail_record.dart';
import '../models/course_price_display.dart';
import '../models/favourite_lesson_record.dart';
import '../models/java_development_course_data.dart';
import '../models/product_design_course_data.dart';
import 'course_catalog_repository.dart';
import 'local_course_catalog_repository.dart';

class RemoteCourseCatalogRepository implements CourseCatalogRepository {
  static const int _genericFreePreviewCount = 2;

  RemoteCourseCatalogRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  static const List<Color> _thumbnailPalette = <Color>[
    Color(0xFFD8F0FF),
    Color(0xFFF2DFFF),
    Color(0xFFFFE5D6),
    Color(0xFFD7F3EE),
    Color(0xFFE3E2FF),
    Color(0xFFFFE4EC),
  ];

  final ApiClient _apiClient;
  final LocalCourseCatalogRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<List<CourseCatalogItem>> loadCachedCourses() {
    return _localStore.loadCourses();
  }

  @override
  Future<List<String>> loadCachedCategories() {
    return _localStore.loadCategories();
  }

  @override
  Future<List<FavouriteLessonRecord>> loadCachedFavouriteLessons() {
    return _localStore.loadFavouriteLessons();
  }

  @override
  Future<void> resetUserScopedState() {
    return _localStore.resetUserScopedState();
  }

  @override
  Future<List<CourseCatalogItem>> loadCourses() async {
    final cachedCourses = await _localStore.loadCourses();

    try {
      final body = await _apiClient.getJson(ApiEndpoints.courses.list);
      final list = _readListPayload(
        body,
        unwrapKeys: const ['data', 'courses'],
        listKeys: const ['courses', 'items', 'results', 'rows', 'data'],
      );

      final courses = list.asMap().entries.map((entry) {
        return _parseCourse(asMap(entry.value), index: entry.key);
      }).where((course) {
        return course.title.trim().isNotEmpty;
      }).toList();

      if (courses.isEmpty) {
        return cachedCourses;
      }

      await _localStore.saveCoursesSnapshot(courses);
      return courses;
    } catch (_) {
      return cachedCourses;
    }
  }

  @override
  Future<List<String>> loadCategories() async {
    final cachedCategories = await _localStore.loadCategories();

    try {
      final body = await _apiClient.getJson(ApiEndpoints.courses.categories);
      final list = _readListPayload(
        body,
        unwrapKeys: const ['data', 'categories'],
        listKeys: const ['categories', 'items', 'results', 'rows', 'data'],
      );

      final categories = list.map((item) {
        if (item is String) {
          return item.trim();
        }

        final map = asMap(item);
        return readString(map, const ['name', 'title', 'label']);
      }).where((category) {
        return category.isNotEmpty;
      }).toSet().toList();

      if (categories.isEmpty) {
        return cachedCategories;
      }

      await _localStore.saveCategoriesSnapshot(categories);
      return categories;
    } catch (_) {
      return cachedCategories;
    }
  }

  @override
  Future<List<FavouriteLessonRecord>> loadFavouriteLessons() async {
    final cachedFavourites = await _localStore.loadFavouriteLessons();
    if (!await _hasAccessToken()) {
      return cachedFavourites;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.favourites.list);
      final payload = unwrapBody(
        body,
        keys: const ['data', 'favourites', 'favorites'],
      );
      final list = payload is List
          ? payload
          : readList(asMap(body), const ['favourites', 'favorites', 'data']);

      final favourites = list.map((item) {
        final root = asMap(item);
        final lesson = readMap(root, const ['lesson', 'video']);
        final course = readMap(root, const ['course']);
        final source = lesson.isEmpty ? root : lesson;

        final lessonId = readString(
          source,
          const ['id', 'lesson_id', 'slug'],
          fallback: readString(root, const ['lesson_id']),
        );
        final title = readString(
          source,
          const ['title', 'name'],
          fallback: readString(root, const ['title', 'name']),
        );

        return FavouriteLessonRecord(
          id: readString(
            root,
            const ['id', 'favourite_id', 'favorite_id'],
            fallback: lessonId.isEmpty ? title : lessonId,
          ),
          lessonId: lessonId,
          courseId: readString(
            course,
            const ['id', 'course_id', 'slug'],
            fallback: readString(root, const ['course_id']),
          ),
          courseTitle: readString(
            course,
            const ['title', 'name'],
            fallback: readString(root, const ['course_title']),
          ),
          title: title,
          durationLabel: readString(
            source,
            const ['duration_label', 'durationLabel', 'duration'],
            fallback: readString(
              root,
              const ['duration_label', 'durationLabel', 'duration'],
              fallback: 'Lesson',
            ),
          ),
        );
      }).where((lesson) {
        return lesson.title.trim().isNotEmpty;
      }).toList();

      if (favourites.isEmpty) {
        return cachedFavourites;
      }

      final mergedFavourites = _mergeFavouriteLessons(
        remoteFavourites: favourites,
        cachedFavourites: cachedFavourites,
      );
      await _localStore.saveFavouriteLessonsSnapshot(mergedFavourites);
      return mergedFavourites;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return cachedFavourites;
    } catch (_) {
      return cachedFavourites;
    }
  }

  @override
  Future<CourseDetailRecord> loadCourseDetail(
    String courseId, {
    CourseCatalogItem? fallbackCourse,
  }) async {
    final fallback = await _localStore.loadCourseDetail(
      courseId,
      fallbackCourse: fallbackCourse,
    );
    if (matchesJavaDevelopmentCourse(
      id: fallback.id.isEmpty ? courseId : fallback.id,
      title: fallback.title,
    )) {
      return fallback;
    }

    try {
      final detailBody = await _apiClient.getJson(
        ApiEndpoints.courses.detail(courseId),
      );
      final detailRoot = asMap(detailBody);
      final detailMap = _readPrimaryMap(
        detailBody,
        unwrapKeys: const ['data', 'course', 'item'],
        mapKeys: const ['course', 'item', 'data'],
      );
      var lessons = _parseLessons(
        _readListPayload(
          detailMap,
          unwrapKeys: const ['lessons', 'data'],
          listKeys: const ['lessons', 'items', 'videos', 'data'],
        ),
      );

      if (lessons.isEmpty) {
        try {
          final lessonsBody = await _apiClient.getJson(
            ApiEndpoints.courses.lessons(courseId),
          );
          lessons = _parseLessons(
            _readListPayload(
              lessonsBody,
              unwrapKeys: const ['data', 'lessons'],
              listKeys: const ['lessons', 'items', 'videos', 'data'],
            ),
          );
        } catch (_) {
          lessons = const <CourseLessonRecord>[];
        }
      }

      final merged = <String, dynamic>{
        ...fallbackCourseToMap(fallbackCourse),
        ...detailRoot,
        ...detailMap,
      };
      final resolvedLessons = _shouldUseJavaDevelopmentAssetLessons(
        courseId: courseId,
        title: readString(
          merged,
          const ['title', 'name'],
          fallback: fallback.title,
        ),
        lessons: lessons,
      )
          ? _buildJavaDevelopmentAssetLessons()
          : (lessons.isEmpty ? fallback.lessons : lessons);
      final parsed = _parseCourseDetail(
        merged,
        fallback: fallback,
        lessons: resolvedLessons,
      );
      return parsed.title.trim().isEmpty ? fallback : parsed;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<void> setCourseFavourite(
    String courseId, {
    required bool isFavourite,
  }) async {
    try {
      if (isFavourite) {
        await _apiClient.postJson(ApiEndpoints.courses.favourite(courseId));
      } else {
        await _apiClient.deleteJson(ApiEndpoints.courses.favourite(courseId));
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      if (!_shouldFallbackToLocal(error)) {
        rethrow;
      }

      await _localStore.setCourseFavourite(
        courseId,
        isFavourite: isFavourite,
      );
      rethrow;
    } catch (_) {
      await _localStore.setCourseFavourite(
        courseId,
        isFavourite: isFavourite,
      );
      rethrow;
    }

    await _localStore.setCourseFavourite(
      courseId,
      isFavourite: isFavourite,
    );
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
    try {
      if (isFavourite) {
        await _apiClient.postJson(ApiEndpoints.favourites.lesson(lessonId));
      } else {
        await _apiClient.deleteJson(ApiEndpoints.favourites.lesson(lessonId));
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      if (!_shouldFallbackToLocal(error)) {
        rethrow;
      }

      await _localStore.setLessonFavourite(
        courseId: courseId,
        courseTitle: courseTitle,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        durationLabel: durationLabel,
        isFavourite: isFavourite,
      );
      rethrow;
    } catch (_) {
      await _localStore.setLessonFavourite(
        courseId: courseId,
        courseTitle: courseTitle,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        durationLabel: durationLabel,
        isFavourite: isFavourite,
      );
      rethrow;
    }

    await _localStore.setLessonFavourite(
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      durationLabel: durationLabel,
      isFavourite: isFavourite,
    );
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
  }

  bool _shouldFallbackToLocal(ApiException error) => error.statusCode == null;

  List<FavouriteLessonRecord> _mergeFavouriteLessons({
    required List<FavouriteLessonRecord> remoteFavourites,
    required List<FavouriteLessonRecord> cachedFavourites,
  }) {
    if (cachedFavourites.isEmpty) {
      return remoteFavourites;
    }

    final merged = List<FavouriteLessonRecord>.from(remoteFavourites);
    for (final cachedLesson in cachedFavourites) {
      final alreadyExists = merged.any((remoteLesson) {
        return _sameFavouriteLesson(remoteLesson, cachedLesson);
      });
      if (!alreadyExists) {
        merged.add(cachedLesson);
      }
    }

    return merged;
  }

  bool _sameFavouriteLesson(
    FavouriteLessonRecord first,
    FavouriteLessonRecord second,
  ) {
    final firstLessonId = first.lessonId.trim().toLowerCase();
    final secondLessonId = second.lessonId.trim().toLowerCase();
    if (firstLessonId.isNotEmpty &&
        secondLessonId.isNotEmpty &&
        firstLessonId == secondLessonId) {
      return true;
    }

    final firstCourseId = first.courseId.trim().toLowerCase();
    final secondCourseId = second.courseId.trim().toLowerCase();
    if (firstCourseId.isNotEmpty &&
        secondCourseId.isNotEmpty &&
        firstCourseId == secondCourseId &&
        _normalizeKey(first.title) == _normalizeKey(second.title)) {
      return true;
    }

    return _normalizeKey(first.courseTitle) == _normalizeKey(second.courseTitle) &&
        _normalizeKey(first.title) == _normalizeKey(second.title);
  }

  String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  List<dynamic> _readListPayload(
    dynamic body, {
    required List<String> unwrapKeys,
    required List<String> listKeys,
  }) {
    if (body is List) {
      return asList(body);
    }

    final payload = unwrapBody(body, keys: unwrapKeys);
    if (payload is List) {
      return asList(payload);
    }

    final payloadList = readList(asMap(payload), listKeys);
    if (payloadList.isNotEmpty) {
      return payloadList;
    }

    return readList(asMap(body), listKeys);
  }

  Map<String, dynamic> _readPrimaryMap(
    dynamic body, {
    required List<String> unwrapKeys,
    required List<String> mapKeys,
  }) {
    if (body is Map<String, dynamic>) {
      final payload = unwrapBody(body, keys: unwrapKeys);
      final payloadMap = asMap(payload);
      if (payloadMap.isNotEmpty) {
        return payloadMap;
      }

      final nested = readMap(body, mapKeys);
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    return asMap(body);
  }

  CourseCatalogItem _parseCourse(
    Map<String, dynamic> map, {
    required int index,
  }) {
    final teacherMap = readMap(
      map,
      const ['teacher', 'instructor', 'mentor', 'author', 'owner', 'user'],
    );
    final categoryMap = readMap(map, const ['category']);
    final id = readString(map, const ['id', 'course_id', 'slug']);
    final title = readString(map, const ['title', 'name'], fallback: 'Course');
    final description = readString(
      map,
      const ['description', 'summary', 'subtitle'],
    );
    final opensProductDetail = _opensProductDetail(id, title);
    final isJavaDevelopment = matchesJavaDevelopmentCourse(
      id: id,
      title: title,
    );
    final normalizedPrice = normalizeCoursePrice(_readPrice(map));

    if (opensProductDetail) {
      ApiConfig.resolveProductDesignCourse(id: id, title: title);
    }

    return CourseCatalogItem(
      id: id,
      title: isJavaDevelopment ? javaDevelopmentCourseTitle : title,
      teacher: readString(
        teacherMap,
        const ['name', 'full_name'],
        fallback: readString(
          map,
          const ['teacher_name', 'instructor_name', 'mentor_name'],
          fallback: 'Course instructor',
        ),
      ),
      price: opensProductDetail
          ? productDesignCoursePriceValue.round()
          : normalizedPrice,
      durationHours: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : _readDurationHours(map),
      category: readString(
        categoryMap,
        const ['name', 'title'],
        fallback: readString(
          map,
          const ['category_name', 'category', 'topic'],
          fallback: 'General',
        ),
      ),
      thumbnailColor: _thumbnailPalette[index % _thumbnailPalette.length],
      lessonCount: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : _readLessonCount(map),
      shortDescription: isJavaDevelopment && description.trim().isEmpty
          ? javaDevelopmentCourseDescription
          : description,
      isPopular: _readPopularFlag(map),
      isNew: _readNewFlag(map),
      isFavourite: _readFavouriteFlag(map),
      opensProductDetail: opensProductDetail,
    );
  }

  CourseDetailRecord _parseCourseDetail(
    Map<String, dynamic> map, {
    required CourseDetailRecord fallback,
    required List<CourseLessonRecord> lessons,
  }) {
    final teacherMap = readMap(
      map,
      const ['teacher', 'instructor', 'mentor', 'author', 'owner', 'user'],
    );
    final categoryMap = readMap(map, const ['category']);
    final title = readString(
      map,
      const ['title', 'name'],
      fallback: fallback.title,
    );
    final lessonCount = _readPositiveInt(
      map,
      const ['lessons_count', 'lesson_count', 'lessonsCount', 'lessonCount'],
      lessons.length,
    );
    final resolvedId = readString(
      map,
      const ['id', 'course_id', 'slug'],
      fallback: fallback.id,
    );
    final isJavaDevelopment = matchesJavaDevelopmentCourse(
      id: resolvedId,
      title: title,
    );
    final normalizedPrice = normalizeCoursePrice(_readPrice(map));
    final resolvedLessons = isJavaDevelopment
        ? _buildJavaDevelopmentAssetLessons()
        : lessons;
    final isPurchased = readBool(
      map,
      const ['is_purchased', 'isPurchased', 'purchased', 'owned', 'is_owned'],
      fallback: fallback.isPurchased || normalizedPrice <= 0,
    );

    return CourseDetailRecord(
      id: resolvedId,
      title: isJavaDevelopment ? javaDevelopmentCourseTitle : title,
      teacher: readString(
        teacherMap,
        const ['name', 'full_name'],
        fallback: readString(
          map,
          const ['teacher_name', 'instructor_name', 'mentor_name'],
          fallback: fallback.teacher,
        ),
      ),
      price: normalizedPrice,
      durationHours: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : _readPositiveInt(
              map,
              const ['duration_hours', 'durationHours', 'hours'],
              fallback.durationHours,
            ),
      category: readString(
        categoryMap,
        const ['name', 'title'],
        fallback: readString(
          map,
          const ['category_name', 'category', 'topic'],
          fallback: fallback.category,
        ),
      ),
      lessonCount: isJavaDevelopment
          ? javaDevelopmentLessons.length
          : lessonCount < resolvedLessons.length
          ? resolvedLessons.length
          : lessonCount,
      description: readString(
        map,
        const ['description', 'summary', 'subtitle'],
        fallback: isJavaDevelopment
            ? javaDevelopmentCourseDescription
            : fallback.description,
      ),
      lessons: _applyGenericPreviewLocks(
        resolvedLessons,
        isPurchased: isPurchased,
        price: normalizedPrice,
      ),
      isPopular: _readPopularFlag(map) || fallback.isPopular,
      isNew: _readNewFlag(map) || fallback.isNew,
      isFavourite: _readFavouriteFlag(map) || fallback.isFavourite,
      isPurchased: isPurchased,
    );
  }

  List<CourseLessonRecord> _parseLessons(List<dynamic> list) {
    return list.map((item) {
      final root = asMap(item);
      final source = _readPrimaryMap(
        item,
        unwrapKeys: const ['lesson', 'video', 'data'],
        mapKeys: const ['lesson', 'video', 'media'],
      );
      final merged = <String, dynamic>{...root, ...source};
      final durationSeconds = _readPositiveInt(
        merged,
        const ['duration_seconds', 'durationSeconds', 'seconds'],
        -1,
      );

      return CourseLessonRecord(
        id: readString(
          merged,
          const ['id', 'lesson_id', 'slug'],
          fallback: readString(root, const ['lesson_id']),
        ),
        title: readString(
          merged,
          const ['title', 'name'],
          fallback: 'Lesson',
        ),
        durationLabel: readString(
          merged,
          const ['duration_label', 'durationLabel', 'duration'],
          fallback: durationSeconds > 0 ? _formatDuration(durationSeconds) : 'Lesson',
        ),
        description: readString(
          merged,
          const ['description', 'summary', 'subtitle'],
        ),
        videoUrl: _readVideoUrl(merged),
        isLocked: readBool(
          merged,
          const ['is_locked', 'isLocked', 'locked'],
          fallback: false,
        ),
        isCompleted: readBool(
          merged,
          const ['is_completed', 'isCompleted', 'completed'],
          fallback: false,
        ),
        positionSeconds: _readPositiveInt(
          merged,
          const ['position_seconds', 'positionSeconds', 'watched_seconds'],
          0,
        ),
      );
    }).where((lesson) {
      return lesson.id.trim().isNotEmpty && lesson.title.trim().isNotEmpty;
    }).toList();
  }

  int _readPrice(Map<String, dynamic> map) {
    final cents = _readMoneyCents(map);
    if (cents >= 0) {
      return (cents / 100).round();
    }

    final nestedMoney = _readMoneyMap(map);
    final nestedMoneyCents = _readMoneyCents(nestedMoney);
    if (nestedMoneyCents >= 0) {
      return (nestedMoneyCents / 100).round();
    }

    final nestedDirectPrice = readInt(
      nestedMoney,
      const ['price', 'amount', 'value', 'major', 'dollars'],
      fallback: -1,
    );
    if (nestedDirectPrice >= 0) {
      return nestedDirectPrice;
    }

    final directPrice = readInt(
      map,
      const ['price', 'amount', 'cost', 'value'],
      fallback: -1,
    );
    if (directPrice >= 0) {
      return directPrice;
    }

    final rawPrice = _readScalarString(
      map,
      const ['price_label', 'amount_label', 'formatted_price', 'formatted'],
    );
    final parsedDirectLabelPrice = _parsePriceText(rawPrice);
    if (parsedDirectLabelPrice >= 0) {
      return parsedDirectLabelPrice;
    }

    final nestedRawPrice = _readScalarString(
      nestedMoney,
      const [
        'formatted',
        'formatted_price',
        'label',
        'display',
        'amount_label',
        'price_label',
        'amount',
        'price',
        'value',
      ],
    );
    final parsedNestedLabelPrice = _parsePriceText(nestedRawPrice);
    if (parsedNestedLabelPrice >= 0) {
      return parsedNestedLabelPrice;
    }

    return 0;
  }

  int _readDurationHours(Map<String, dynamic> map) {
    final durationMinutes = readInt(
      map,
      const ['duration_minutes', 'durationMinutes'],
      fallback: -1,
    );
    if (durationMinutes >= 0) {
      return (durationMinutes / 60).ceil();
    }

    final directHours = readInt(
      map,
      const ['duration_hours', 'durationHours', 'hours'],
      fallback: -1,
    );
    if (directHours >= 0) {
      return directHours;
    }

    final rawDuration = readString(
      map,
      const ['duration', 'duration_label', 'durationLabel'],
    );
    final matched = RegExp(r'(\d+)').firstMatch(rawDuration);
    return int.tryParse(matched?.group(1) ?? '') ?? 0;
  }

  int _readLessonCount(Map<String, dynamic> map) {
    final directCount = readInt(
      map,
      const ['lessons_count', 'lesson_count', 'lessonsCount', 'lessonCount'],
      fallback: -1,
    );
    if (directCount >= 0) {
      return directCount;
    }

    final lessons = readList(map, const ['lessons']);
    return lessons.length;
  }

  int _readMoneyCents(Map<String, dynamic> map) {
    return readInt(
      map,
      const [
        'price_cents',
        'priceCents',
        'amount_cents',
        'amountCents',
        'cents',
        'minor',
      ],
      fallback: -1,
    );
  }

  Map<String, dynamic> _readMoneyMap(Map<String, dynamic> map) {
    return readMap(
      map,
      const [
        'price',
        'amount',
        'pricing',
        'cost',
        'money',
        'value',
      ],
    );
  }

  String _readScalarString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null || value is Map || value is List) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  int _parsePriceText(String rawPrice) {
    final normalized = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) {
      return -1;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return -1;
    }

    return parsed.round();
  }

  bool _readPopularFlag(Map<String, dynamic> map) {
    if (readBool(map, const ['is_popular', 'isPopular'])) {
      return true;
    }

    final badge = readString(map, const ['badge', 'tag']).toLowerCase();
    return badge.contains('popular');
  }

  bool _readNewFlag(Map<String, dynamic> map) {
    if (readBool(map, const ['is_new', 'isNew'])) {
      return true;
    }

    final badge = readString(map, const ['badge', 'tag']).toLowerCase();
    return badge.contains('new');
  }

  bool _readFavouriteFlag(Map<String, dynamic> map) {
    return readBool(
      map,
      const ['is_favourite', 'isFavorite', 'favourited', 'favorited'],
      fallback: false,
    );
  }

  int _readPositiveInt(
    Map<String, dynamic> map,
    List<String> keys,
    int fallback,
  ) {
    final value = readInt(map, keys, fallback: fallback);
    return value < 0 ? fallback : value;
  }

  String _readVideoUrl(Map<String, dynamic> map) {
    final media = readMap(map, const ['media', 'video', 'source', 'file']);
    final rawUrl = readString(
      <String, dynamic>{...map, ...media},
      const [
        'video_url',
        'videoUrl',
        'stream_url',
        'streamUrl',
        'playback_url',
        'playbackUrl',
        'url',
        'file_url',
        'fileUrl',
      ],
    );
    if (rawUrl.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri != null && uri.hasScheme) {
      return rawUrl;
    }

    return Uri.parse(ApiConfig.baseUrl).resolve(rawUrl).toString();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    if (minutes <= 0) {
      return '$totalSeconds sec';
    }
    return '$minutes:$seconds mins';
  }

  Map<String, dynamic> fallbackCourseToMap(CourseCatalogItem? course) {
    if (course == null) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{
      'id': course.id,
      'title': course.title,
      'teacher_name': course.teacher,
      'price': course.price,
      'duration_hours': course.durationHours,
      'category': course.category,
      'lessons_count': course.lessonCount,
      'description': course.shortDescription,
      'is_popular': course.isPopular,
      'is_new': course.isNew,
      'is_favourite': course.isFavourite,
    };
  }

  bool _opensProductDetail(String id, String title) {
    return ApiConfig.matchesProductDesignCourse(id: id, title: title);
  }

  bool _shouldUseJavaDevelopmentAssetLessons({
    required String courseId,
    required String title,
    required List<CourseLessonRecord> lessons,
  }) {
    if (!matchesJavaDevelopmentCourse(id: courseId, title: title)) {
      return false;
    }

    return true;
  }

  List<CourseLessonRecord> _buildJavaDevelopmentAssetLessons() {
    return javaDevelopmentLessons.map((lesson) {
      return CourseLessonRecord(
        id: lesson.id,
        title: lesson.title,
        durationLabel: lesson.fallbackDurationLabel,
        videoUrl: lesson.assetPath,
      );
    }).toList();
  }

  List<CourseLessonRecord> _applyGenericPreviewLocks(
    List<CourseLessonRecord> lessons, {
    required bool isPurchased,
    required int price,
  }) {
    if (isPurchased || price <= 0) {
      return lessons;
    }

    return lessons.asMap().entries.map((entry) {
      final index = entry.key;
      final lesson = entry.value;
      return CourseLessonRecord(
        id: lesson.id,
        title: lesson.title,
        durationLabel: lesson.durationLabel,
        description: lesson.description,
        videoUrl: lesson.videoUrl,
        isLocked: lesson.isLocked || index >= _genericFreePreviewCount,
        isCompleted: lesson.isCompleted,
        positionSeconds: lesson.positionSeconds,
      );
    }).toList();
  }
}
