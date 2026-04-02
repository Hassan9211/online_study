import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/course_catalog_controller.dart';
import '../controllers/home_dashboard_controller.dart';
import '../controllers/product_design_course_controller.dart';
import '../models/product_design_course_data.dart';

class ProductDesignPlayerScreen extends StatefulWidget {
  const ProductDesignPlayerScreen({super.key});

  @override
  State<ProductDesignPlayerScreen> createState() =>
      _ProductDesignPlayerScreenState();
}

class _ProductDesignPlayerScreenState extends State<ProductDesignPlayerScreen> {
  VideoPlayerController? _videoController;
  int _currentLessonIndex = 0;
  bool _isLoading = true;
  bool _showOverlayControl = true;
  int _loadRequestId = 0;
  Timer? _overlayHideTimer;
  Timer? _progressSyncTimer;
  DateTime? _lastWatchTickAt;
  bool _wasPlaying = false;

  ProductDesignCourseController get _courseController =>
      Get.find<ProductDesignCourseController>();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is Map && arguments['lessonIndex'] is int) {
      _currentLessonIndex = arguments['lessonIndex'] as int;
    }
    _loadLesson(_currentLessonIndex, autoPlay: true);
  }

  @override
  void dispose() {
    _stopProgressTracking(flush: true);
    _overlayHideTimer?.cancel();
    _videoController?.removeListener(_handleVideoValueChanged);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadLesson(int index, {bool autoPlay = false}) async {
    _stopProgressTracking(flush: true);
    final requestId = ++_loadRequestId;
    final previousController = _videoController;
    final controller = VideoPlayerController.asset(
      productDesignLessons[index].assetPath,
    );
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

  void _handlePlayerSurfaceTap() {
    _showControls();
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

    final lesson = productDesignLessons[_currentLessonIndex];
    await Get.find<HomeDashboardController>().recordLessonProgress(
      courseId: ApiConfig.productDesignCourseId,
      lessonId: lesson.id,
      position: controller.value.position,
      totalDuration: controller.value.duration,
      watchedDelta: watchedDelta,
      courseTitle: productDesignCourseTitle,
      totalLessons: productDesignLessons.length,
    );
  }

  Future<void> _selectLesson(int index) async {
    if (_courseController.isLessonLocked(index)) {
      Get.snackbar(
        'Video Locked',
        'Purchase the course to unlock this video.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    await _loadLesson(index, autoPlay: true);
  }

  void _buyCourse() {
    if (_courseController.isPurchased) {
      return;
    }
    Get.toNamed(AppRoutes.productDesignPayment);
  }

  Future<void> _toggleLessonFavourite(
    CourseCatalogController catalogController,
  ) async {
    final lesson = productDesignLessons[_currentLessonIndex];
    final isFavourite = catalogController.isLessonFavourite(lesson.id);
    final nextValue = !isFavourite;
    final didUpdate = await catalogController.setLessonFavourite(
      courseId: ApiConfig.productDesignCourseId,
      courseTitle: productDesignCourseTitle,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      durationLabel: _courseController.lessonDurationLabel(_currentLessonIndex),
      isFavourite: nextValue,
    );

    if (!mounted) {
      return;
    }

    if (!didUpdate) {
      Get.snackbar(
        'Favourite Update Failed',
        catalogController.lastErrorMessage.isEmpty
            ? 'Could not update the favourite lesson right now.'
            : catalogController.lastErrorMessage,
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
    final screenSize = MediaQuery.sizeOf(context);
    final maxPlayerHeight = screenSize.height * 0.42;

    return GetBuilder<CourseCatalogController>(
      builder: (catalogController) {
        final isFavourite = catalogController.isLessonFavourite(
          productDesignLessons[_currentLessonIndex].id,
        );
        return GetBuilder<ProductDesignCourseController>(
          builder: (controller) {
            final currentLesson = productDesignLessons[_currentLessonIndex];
            final isPlaying = _videoController?.value.isPlaying ?? false;

            return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLessonFavourite(catalogController),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 62,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isFavourite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.warmAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: controller.isPurchased ? 'Purchased' : 'Buy Now',
                      onPressed: controller.isPurchased ? null : _buyCourse,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                            const Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.white,
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
                          '${controller.lessonDurationLabel(_currentLessonIndex)} | $productDesignCourseTitle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AdaptivePlayerSurface(
                          controller: _videoController,
                          isLoading: _isLoading,
                          isPlaying: isPlaying,
                          showOverlayControl: _showOverlayControl,
                          maxHeight: maxPlayerHeight,
                          onSurfaceTap: _handlePlayerSurfaceTap,
                          onControlPressed: _togglePlayback,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _formatDuration(
                                _videoController?.value.position ??
                                    Duration.zero,
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
                                          bufferedColor: Colors.white
                                              .withValues(alpha: 0.35),
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.18),
                                        ),
                                      )
                                    : Container(
                                        height: 3,
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(
                                _videoController?.value.duration ??
                                    Duration.zero,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
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
                                    'Playable videos',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.heading,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.courseMetaLabel,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              productDesignCoursePriceLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: AppColors.dividerSoft,
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                          itemCount: productDesignLessons.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final lesson = productDesignLessons[index];
                            final isLocked = controller.isLessonLocked(index);
                            final isCurrent = index == _currentLessonIndex;

                            return _PlayerLessonRow(
                              index: index,
                              title: lesson.title,
                              durationLabel:
                                  controller.lessonDurationLabel(index),
                              isLocked: isLocked,
                              isCurrent: isCurrent,
                              isPlaying: isCurrent && isPlaying,
                              onTap: () => _selectLesson(index),
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
          },
        );
      },
    );
  }
}

class _AdaptivePlayerSurface extends StatelessWidget {
  const _AdaptivePlayerSurface({
    required this.controller,
    required this.isLoading,
    required this.isPlaying,
    required this.showOverlayControl,
    required this.maxHeight,
    required this.onSurfaceTap,
    required this.onControlPressed,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final bool isPlaying;
  final bool showOverlayControl;
  final double maxHeight;
  final VoidCallback onSurfaceTap;
  final VoidCallback onControlPressed;

  @override
  Widget build(BuildContext context) {
    const minHeight = 220.0;
    final maxWidth = MediaQuery.sizeOf(context).width - 32;
    final aspectRatio = _resolvedAspectRatio(controller);
    final naturalHeight = maxWidth / aspectRatio;
    final playerHeight = naturalHeight.clamp(minHeight, maxHeight);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSurfaceTap,
      child: SizedBox(
        width: double.infinity,
        height: playerHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null &&
                    !isLoading &&
                    controller!.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: VideoPlayer(controller!),
                    ),
                  )
                else
                  const _PlayerLoadingView(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.26),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                else
                  Center(
                    child: IgnorePointer(
                      ignoring: !showOverlayControl,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: showOverlayControl ? 1 : 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onControlPressed,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerLoadingView extends StatelessWidget {
  const _PlayerLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121016),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Color(0x66FFFFFF),
          size: 54,
        ),
      ),
    );
  }
}

class _PlayerLessonRow extends StatelessWidget {
  const _PlayerLessonRow({
    required this.index,
    required this.title,
    required this.durationLabel,
    required this.isLocked,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final int index;
  final String title;
  final String durationLabel;
  final bool isLocked;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFF4F6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFC9CDE2),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      durationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLocked
                            ? AppColors.mutedText
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.warmAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFFDDE2FF) : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: isLocked
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : isCurrent && isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _resolvedAspectRatio(VideoPlayerController? controller) {
  if (controller == null || !controller.value.isInitialized) {
    return 16 / 9;
  }

  final aspectRatio = controller.value.aspectRatio;
  if (!aspectRatio.isFinite || aspectRatio <= 0) {
    return 16 / 9;
  }

  return aspectRatio;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
