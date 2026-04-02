import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/course_catalog_controller.dart';
import '../controllers/home_dashboard_controller.dart';
import '../models/course_detail_record.dart';

class CoursePlayerScreen extends StatefulWidget {
  const CoursePlayerScreen({super.key});

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  late final CourseDetailRecord _detail;
  late int _currentLessonIndex;

  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _showOverlayControl = true;
  int _loadRequestId = 0;
  Timer? _overlayHideTimer;
  Timer? _progressSyncTimer;
  DateTime? _lastWatchTickAt;
  bool _wasPlaying = false;
  bool _isLessonFavourite = false;

  CourseCatalogController get _catalogController =>
      Get.find<CourseCatalogController>();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map? ?? <String, dynamic>{};
    _detail = arguments['detail'] as CourseDetailRecord;
    _currentLessonIndex = arguments['lessonIndex'] as int? ?? 0;
    _isLessonFavourite = _catalogController.isLessonFavourite(
      _detail.lessons[_currentLessonIndex].id,
    );
    _loadLesson(_currentLessonIndex, autoPlay: true);
  }

  @override
  void dispose() {
    _stopProgressTracking(flush: true);
    _overlayHideTimer?.cancel();
    _videoController?.removeListener(_handleVideoValueChanged);
    _videoController?.dispose();
    if (Get.isRegistered<HomeDashboardController>()) {
      Get.find<HomeDashboardController>().refreshAll();
    }
    super.dispose();
  }

  Future<void> _loadLesson(int index, {bool autoPlay = false}) async {
    _stopProgressTracking(flush: true);
    final requestId = ++_loadRequestId;
    final previousController = _videoController;
    final lesson = _detail.lessons[index];
    _isLessonFavourite = _catalogController.isLessonFavourite(lesson.id);

    if (lesson.videoUrl.trim().isEmpty) {
      previousController?.removeListener(_handleVideoValueChanged);
      await previousController?.dispose();
      if (!mounted || requestId != _loadRequestId) {
        return;
      }
      setState(() {
        _currentLessonIndex = index;
        _isLoading = false;
        _showOverlayControl = true;
        _videoController = null;
      });
      return;
    }

    final controller = _createVideoController(lesson.videoUrl);
    controller.addListener(_handleVideoValueChanged);
    previousController?.removeListener(_handleVideoValueChanged);
    _overlayHideTimer?.cancel();

    setState(() {
      _currentLessonIndex = index;
      _isLoading = true;
      _showOverlayControl = true;
      _videoController = controller;
    });
    _lastWatchTickAt = null;
    _wasPlaying = false;

    try {
      await controller.initialize();
      await controller.setLooping(false);

      if (!mounted || requestId != _loadRequestId) {
        await controller.dispose();
        return;
      }

      await previousController?.dispose();

      if (autoPlay) {
        await controller.play();
      }

      if (!mounted || requestId != _loadRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      _scheduleOverlayHide();
    } catch (_) {
      await controller.dispose();
      if (!mounted || requestId != _loadRequestId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _videoController = null;
      });
    }
  }

  VideoPlayerController _createVideoController(String source) {
    if (_isAssetVideoSource(source)) {
      return VideoPlayerController.asset(source);
    }
    return VideoPlayerController.networkUrl(Uri.parse(source));
  }

  bool _isAssetVideoSource(String source) {
    return source.trim().toLowerCase().startsWith('assets/');
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;
    if (controller == null || _isLoading) {
      return;
    }

    _showControls();
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
    _scheduleOverlayHide();
  }

  void _showControls() {
    _overlayHideTimer?.cancel();
    if (!_showOverlayControl && mounted) {
      setState(() {
        _showOverlayControl = true;
      });
    }
  }

  void _scheduleOverlayHide() {
    _overlayHideTimer?.cancel();
    final controller = _videoController;
    if (controller == null || _isLoading || !controller.value.isPlaying) {
      return;
    }
    _overlayHideTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showOverlayControl = false;
      });
    });
  }

  void _handleVideoValueChanged() {
    if (!mounted) {
      return;
    }

    final controller = _videoController;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    if (value.isPlaying != _wasPlaying) {
      _wasPlaying = value.isPlaying;
      if (_wasPlaying) {
        _startProgressTracking();
      } else {
        _stopProgressTracking(flush: true);
      }
    }

    final hasEnded = value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration &&
        !value.isPlaying;
    if (hasEnded) {
      _stopProgressTracking(flush: true);
      _overlayHideTimer?.cancel();
      if (!_showOverlayControl) {
        setState(() {
          _showOverlayControl = true;
        });
        return;
      }
    }

    setState(() {});
  }

  void _startProgressTracking() {
    _progressSyncTimer?.cancel();
    _lastWatchTickAt = DateTime.now();
    _progressSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _recordPlaybackProgress();
    });
  }

  void _stopProgressTracking({bool flush = false}) {
    _progressSyncTimer?.cancel();
    _progressSyncTimer = null;
    if (flush) {
      _recordPlaybackProgress(force: true);
    }
    _lastWatchTickAt = null;
  }

  Future<void> _recordPlaybackProgress({bool force = false}) async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final now = DateTime.now();
    final lastWatchTickAt = _lastWatchTickAt;
    final rawDelta = lastWatchTickAt == null
        ? Duration.zero
        : now.difference(lastWatchTickAt);
    final watchedDelta = rawDelta > const Duration(seconds: 12)
        ? const Duration(seconds: 12)
        : rawDelta;
    _lastWatchTickAt = now;

    if (!force && watchedDelta <= Duration.zero) {
      return;
    }

    if (!Get.isRegistered<HomeDashboardController>()) {
      return;
    }

    final lesson = _detail.lessons[_currentLessonIndex];
    await Get.find<HomeDashboardController>().recordLessonProgress(
      courseId: _detail.id,
      lessonId: lesson.id,
      position: controller.value.position,
      totalDuration: controller.value.duration,
      watchedDelta: watchedDelta,
      courseTitle: _detail.title,
      totalLessons: _detail.lessonCount,
    );
  }

  Future<void> _selectLesson(int index) async {
    final lesson = _detail.lessons[index];
    if (lesson.isLocked && !_detail.isPurchased) {
      Get.snackbar(
        'Lesson Locked',
        'This lesson is locked until the course is unlocked.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    await _loadLesson(index, autoPlay: true);
  }

  Future<void> _toggleLessonFavourite() async {
    final lesson = _detail.lessons[_currentLessonIndex];
    final nextValue = !_isLessonFavourite;
    setState(() {
      _isLessonFavourite = nextValue;
    });

    final didUpdate = await _catalogController.setLessonFavourite(
      courseId: _detail.id,
      courseTitle: _detail.title,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      durationLabel: lesson.durationLabel,
      isFavourite: nextValue,
    );
    if (!mounted) {
      return;
    }

    if (!didUpdate) {
      setState(() {
        _isLessonFavourite = !nextValue;
      });
      Get.snackbar(
        'Favourite Update Failed',
        _catalogController.lastErrorMessage.isEmpty
            ? 'Could not update the favourite lesson right now.'
            : _catalogController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.snackbar(
      nextValue ? 'Lesson Saved' : 'Lesson Removed',
      nextValue
          ? 'This lesson was added to your favourites.'
          : 'This lesson was removed from your favourites.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLesson = _detail.lessons[_currentLessonIndex];
    final isPlaying = _videoController?.value.isPlaying ?? false;
    final screenSize = MediaQuery.sizeOf(context);
    final maxPlayerHeight = screenSize.height * 0.38;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF17151F),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: Get.back,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _toggleLessonFavourite,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isLessonFavourite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.warmAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLesson.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentLesson.durationLabel} | ${_detail.title}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdaptiveNetworkPlayerSurface(
                      controller: _videoController,
                      isLoading: _isLoading,
                      isPlaying: isPlaying,
                      showOverlayControl: _showOverlayControl,
                      maxHeight: maxPlayerHeight,
                      hasVideo: currentLesson.videoUrl.trim().isNotEmpty,
                      onSurfaceTap: _showControls,
                      onControlPressed: _togglePlayback,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          _formatDuration(
                            _videoController?.value.position ?? Duration.zero,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: _videoController != null
                                ? VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                    padding: EdgeInsets.zero,
                                    colors: VideoProgressColors(
                                      playedColor: AppColors.warmAccent,
                                      bufferedColor: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 3,
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatDuration(
                            _videoController?.value.duration ?? Duration.zero,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course lessons',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.heading,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _detail.metaLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _detail.priceLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.dividerSoft),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: _detail.lessons.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lesson = _detail.lessons[index];
                        final isSelected = index == _currentLessonIndex;
                        final isLocked = lesson.isLocked && !_detail.isPurchased;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectLesson(index),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF4F2FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.22)
                                      : AppColors.dividerSoft,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? const Color(0xFFF4F4FA)
                                          : AppColors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLocked
                                          ? Icons.lock_outline_rounded
                                          : isSelected
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isLocked
                                          ? AppColors.mutedText
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lesson.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            color: AppColors.heading,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.durationLabel,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveNetworkPlayerSurface extends StatelessWidget {
  const _AdaptiveNetworkPlayerSurface({
    required this.controller,
    required this.isLoading,
    required this.isPlaying,
    required this.showOverlayControl,
    required this.maxHeight,
    required this.hasVideo,
    required this.onSurfaceTap,
    required this.onControlPressed,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final bool isPlaying;
  final bool showOverlayControl;
  final double maxHeight;
  final bool hasVideo;
  final VoidCallback onSurfaceTap;
  final VoidCallback onControlPressed;

  @override
  Widget build(BuildContext context) {
    final hasInitializedController =
        controller != null && controller!.value.isInitialized;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final aspectRatio = hasInitializedController
            ? controller!.value.aspectRatio
            : 16 / 9;
        final calculatedHeight = width / aspectRatio;
        final playerHeight = calculatedHeight > maxHeight
            ? maxHeight
            : calculatedHeight;

        return GestureDetector(
          onTap: onSurfaceTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: width,
              height: playerHeight,
              color: const Color(0xFF0F1017),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasInitializedController)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller!.value.size.width,
                          height: controller!.value.size.height,
                          child: VideoPlayer(controller!),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        hasVideo
                            ? 'Loading video...'
                            : 'This lesson does not have a playable video URL yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.45,
                        ),
                      ),
                    ),
                  if (isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (hasVideo && showOverlayControl)
                    Material(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onControlPressed,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
