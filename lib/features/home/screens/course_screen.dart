import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/course_catalog_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/course_catalog_data.dart';
import '../widgets/profile_avatar.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  static const double _minPrice = 0;
  static const double _maxPrice = 100;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedCategories = <String>{};

  int _selectedFilter = 0;
  String? _selectedDuration;
  RangeValues _selectedPriceRange = const RangeValues(_minPrice, _maxPrice);

  bool get _hasActiveFilters {
    return _selectedCategories.isNotEmpty ||
        _selectedDuration != null ||
        _selectedPriceRange.start != _minPrice ||
        _selectedPriceRange.end != _maxPrice;
  }

  bool get _isSearchMode => _searchController.text.trim().isNotEmpty;

  bool get _hasCustomPriceRange {
    return _selectedPriceRange.start > _minPrice ||
        _selectedPriceRange.end < _maxPrice;
  }

  List<CourseCatalogItem> _visibleCoursesFor(List<CourseCatalogItem> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((course) {
      final matchesTopFilter = switch (_selectedFilter) {
        1 => course.isPopular,
        2 => course.isNew,
        _ => true,
      };

      final matchesSearch =
          query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.teacher.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(course.category);

      final matchesPrice =
          !_hasCustomPriceRange ||
          (course.displayPrice >= _selectedPriceRange.start.round() &&
              course.displayPrice <= _selectedPriceRange.end.round());

      final durationRange = courseDurationRangeFor(_selectedDuration);
      final matchesDuration =
          durationRange == null ||
          (course.durationHours >= durationRange.$1 &&
              course.durationHours <= durationRange.$2);

      return matchesTopFilter &&
          matchesSearch &&
          matchesCategory &&
          matchesPrice &&
          matchesDuration;
    }).toList();
  }

  List<String> _availableCategoriesFor(List<String> remoteCategories) {
    return remoteCategories.isEmpty ? courseFilterCategories : remoteCategories;
  }

  List<_CategoryOverviewCardData> _categoryCardsFor(
    List<String> remoteCategories,
    List<CourseCatalogItem> courses,
  ) {
    final availableCategories = _availableCategoriesFor(remoteCategories);
    final categoryCounts = <String, int>{};
    for (final course in courses) {
      final category = course.category.trim();
      if (category.isEmpty) {
        continue;
      }

      categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
    }

    final categories = <String>[
      ...availableCategories,
      ...categoryCounts.keys.where(
        (category) => !availableCategories.contains(category),
      ),
    ];

    if (categories.isEmpty) {
      return _fallbackCategoryCards;
    }

    return categories.take(6).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final palette = _categoryPaletteFor(index);
      final courseCount = categoryCounts[category] ?? 0;

      return _CategoryOverviewCardData(
        title: category,
        subtitle: courseCount == 1 ? '1 course' : '$courseCount courses',
        backgroundColor: palette.backgroundColor,
        accentColor: palette.accentColor,
        width: index == 0 ? 168 : 128,
        type: _categoryArtTypeFor(index),
      );
    }).toList();
  }

  _CategoryCardPalette _categoryPaletteFor(int index) {
    const palettes = <_CategoryCardPalette>[
      _CategoryCardPalette(
        backgroundColor: Color(0xFFD8F0FF),
        accentColor: AppColors.primary,
      ),
      _CategoryCardPalette(
        backgroundColor: Color(0xFFF2DFFF),
        accentColor: Color(0xFFB66BFF),
      ),
      _CategoryCardPalette(
        backgroundColor: Color(0xFFFFE5D6),
        accentColor: AppColors.warmAccent,
      ),
      _CategoryCardPalette(
        backgroundColor: Color(0xFFD7F3EE),
        accentColor: Color(0xFF1EA884),
      ),
      _CategoryCardPalette(
        backgroundColor: Color(0xFFE3E2FF),
        accentColor: Color(0xFF6F5CFF),
      ),
      _CategoryCardPalette(
        backgroundColor: Color(0xFFFFE4EC),
        accentColor: Color(0xFFFF6B8A),
      ),
    ];

    return palettes[index % palettes.length];
  }

  _CategoryArtType _categoryArtTypeFor(int index) {
    const types = <_CategoryArtType>[
      _CategoryArtType.language,
      _CategoryArtType.painting,
      _CategoryArtType.music,
    ];

    return types[index % types.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchQuery(String value) {
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  Future<void> _openFilterSheet() async {
    final catalogController = Get.find<CourseCatalogController>();
    final result = await showModalBottomSheet<_CourseFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CourseFilterSheet(
          availableCategories: _availableCategoriesFor(
            catalogController.categories,
          ),
          initialCategories: _selectedCategories,
          initialDuration: _selectedDuration,
          initialPriceRange: _selectedPriceRange,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(result.categories);
      _selectedDuration = result.duration;
      _selectedPriceRange = result.priceRange;
    });
  }

  void _openCourse(CourseCatalogItem course) {
    if (course.opensProductDetail) {
      ApiConfig.resolveProductDesignCourse(id: course.id, title: course.title);
      Get.toNamed(
        AppRoutes.productDesignCourse,
        arguments: <String, dynamic>{
          'courseId': course.id,
          'courseTitle': course.title,
        },
      );
      return;
    }
    Get.toNamed(
      AppRoutes.courseDetail,
      arguments: <String, dynamic>{
        'courseId': course.id,
        'course': course,
      },
    );
  }

  Future<void> _refreshCatalog() async {
    final refreshTasks = <Future<void>>[
      Get.find<CourseCatalogController>().refreshAll(),
    ];
    if (Get.isRegistered<ProfileController>()) {
      refreshTasks.add(Get.find<ProfileController>().refreshProfile());
    }
    await Future.wait<void>(refreshTasks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<CourseCatalogController>(
      builder: (catalogController) {
        final searchSuggestions = catalogController.searchSuggestions.isEmpty
            ? courseSearchSuggestions
            : catalogController.searchSuggestions;
        final visibleCourses = _visibleCoursesFor(catalogController.courses);
        final categoryCards = _categoryCardsFor(
          catalogController.categories,
          catalogController.courses,
        );

        return Container(
          color: Colors.white,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshCatalog,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  if (_isSearchMode) ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.visibility_off_outlined,
                            color: AppColors.heading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _CourseSearchBar(
                      controller: _searchController,
                      hasActiveFilters: _hasActiveFilters,
                      onChanged: (_) => setState(() {}),
                      onClear: _clearSearch,
                      onOpenFilter: _openFilterSheet,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: searchSuggestions.map((suggestion) {
                        return _SearchSuggestionChip(
                          label: suggestion,
                          onTap: () => _setSearchQuery(suggestion),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Results',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Course',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ProfileAvatar(
                          size: 38,
                          onTap: () => Get.toNamed(AppRoutes.editAccount),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.heading.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          innerPadding: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _CourseSearchBar(
                      controller: _searchController,
                      hasActiveFilters: _hasActiveFilters,
                      onChanged: (_) => setState(() {}),
                      onClear: _clearSearch,
                      onOpenFilter: _openFilterSheet,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categoryCards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final card = categoryCards[index];
                          return _CourseCategoryCard(
                            title: card.title,
                            subtitle: card.subtitle,
                            backgroundColor: card.backgroundColor,
                            accentColor: card.accentColor,
                            width: card.width,
                            type: card.type,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Choose your course',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _selectedFilter == 0,
                          onTap: () => setState(() => _selectedFilter = 0),
                        ),
                        const SizedBox(width: 12),
                        _FilterChip(
                          label: 'Popular',
                          isSelected: _selectedFilter == 1,
                          onTap: () => setState(() => _selectedFilter = 1),
                        ),
                        const SizedBox(width: 12),
                        _FilterChip(
                          label: 'New',
                          isSelected: _selectedFilter == 2,
                          onTap: () => setState(() => _selectedFilter = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (catalogController.lastErrorMessage.isNotEmpty) ...[
                    Text(
                      catalogController.lastErrorMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (catalogController.isLoadingCatalog &&
                      catalogController.courses.isEmpty)
                    const _CourseLoadingState()
                  else if (visibleCourses.isEmpty)
                    const _EmptyCourseState()
                  else
                    ...visibleCourses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CourseListItem(
                          course: course,
                          onTap: () => _openCourse(course),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

const List<_CategoryOverviewCardData> _fallbackCategoryCards =
    <_CategoryOverviewCardData>[
      _CategoryOverviewCardData(
        title: 'Language',
        subtitle: '24 courses',
        backgroundColor: Color(0xFFD8F0FF),
        accentColor: AppColors.primary,
        width: 168,
        type: _CategoryArtType.language,
      ),
      _CategoryOverviewCardData(
        title: 'Painting',
        subtitle: '18 courses',
        backgroundColor: Color(0xFFF2DFFF),
        accentColor: Color(0xFFB66BFF),
        width: 128,
        type: _CategoryArtType.painting,
      ),
      _CategoryOverviewCardData(
        title: 'Music',
        subtitle: '12 courses',
        backgroundColor: Color(0xFFFFE5D6),
        accentColor: AppColors.warmAccent,
        width: 128,
        type: _CategoryArtType.music,
      ),
    ];

class _CategoryOverviewCardData {
  const _CategoryOverviewCardData({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
    required this.width,
    required this.type,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;
  final double width;
  final _CategoryArtType type;
}

class _CategoryCardPalette {
  const _CategoryCardPalette({
    required this.backgroundColor,
    required this.accentColor,
  });

  final Color backgroundColor;
  final Color accentColor;
}

class _CourseFilterSheet extends StatefulWidget {
  const _CourseFilterSheet({
    required this.availableCategories,
    required this.initialCategories,
    required this.initialDuration,
    required this.initialPriceRange,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<String> availableCategories;
  final Set<String> initialCategories;
  final String? initialDuration;
  final RangeValues initialPriceRange;
  final double minPrice;
  final double maxPrice;

  @override
  State<_CourseFilterSheet> createState() => _CourseFilterSheetState();
}

class _CourseFilterSheetState extends State<_CourseFilterSheet> {
  late Set<String> _categories;
  late String? _duration;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initialCategories};
    _duration = widget.initialDuration;
    _priceRange = widget.initialPriceRange;
  }

  void _resetFilters() {
    setState(() {
      _categories.clear();
      _duration = null;
      _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: AppColors.heading),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Search Filter',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Categories',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: widget.availableCategories.map((category) {
                  final isSelected = _categories.contains(category);
                  return _SheetChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _categories.remove(category);
                        } else {
                          _categories.add(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Text(
                'Price',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.inputBorder,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  trackHeight: 2,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: RangeSlider(
                  values: _priceRange,
                  min: widget.minPrice,
                  max: widget.maxPrice,
                  divisions: (widget.maxPrice - widget.minPrice).round(),
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_priceRange.start.round()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${_priceRange.end.round()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Duration',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: courseDurationOptions.map((duration) {
                  return _SheetChip(
                    label: duration,
                    isSelected: _duration == duration,
                    onTap: () {
                      setState(() {
                        _duration = _duration == duration ? null : duration;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Clear',
                      onPressed: _resetFilters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: 'Apply Filter',
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _CourseFilterResult(
                            categories: _categories,
                            duration: _duration,
                            priceRange: _priceRange,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseFilterResult {
  const _CourseFilterResult({
    required this.categories,
    required this.duration,
    required this.priceRange,
  });

  final Set<String> categories;
  final String? duration;
  final RangeValues priceRange;
}

class _CourseSearchBar extends StatelessWidget {
  const _CourseSearchBar({
    required this.controller,
    required this.hasActiveFilters,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilter,
  });

  final TextEditingController controller;
  final bool hasActiveFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppColors.mutedText.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Find Course',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: AppColors.mutedText.withValues(alpha: 0.9),
                ),
              ),
            ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onOpenFilter,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: hasActiveFilters
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters
                    ? AppColors.primary
                    : AppColors.mutedText.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSuggestionChip extends StatelessWidget {
  const _SearchSuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CourseCategoryCard extends StatelessWidget {
  const _CourseCategoryCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
    required this.width,
    required this.type,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;
  final double width;
  final _CategoryArtType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _CategoryArtwork(accentColor: accentColor, type: type),
          ),
          Positioned(
            right: 0,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width - 68,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inputText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CategoryArtType { language, painting, music }

class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({required this.accentColor, required this.type});

  final Color accentColor;
  final _CategoryArtType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _CategoryArtType.language:
        return SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            children: [
              Positioned(
                left: 12,
                bottom: 0,
                child: Container(
                  width: 46,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                top: 10,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.skin,
                ),
              ),
              const Positioned(
                left: 14,
                top: 4,
                child: SizedBox(
                  width: 24,
                  height: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.avatarHair,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CategoryArtType.painting:
        return SizedBox(
          width: 84,
          height: 82,
          child: Stack(
            children: [
              Positioned(
                left: 6,
                top: 12,
                child: Container(
                  width: 38,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: 6,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.warmAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                top: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.skin,
                ),
              ),
              const Positioned(
                left: 14,
                top: 0,
                child: SizedBox(
                  width: 18,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.avatarHair,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CategoryArtType.music:
        return SizedBox(
          width: 84,
          height: 82,
          child: Stack(
            children: [
              Positioned(
                left: 18,
                bottom: 0,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const Positioned(
                left: 26,
                top: 8,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.skin,
                ),
              ),
              const Positioned(
                left: 21,
                top: 4,
                child: SizedBox(
                  width: 20,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.orangeHair,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppColors.mutedText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppColors.mutedText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CourseListItem extends StatelessWidget {
  const _CourseListItem({required this.course, this.onTap});

  final CourseCatalogItem course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.heading.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: course.thumbnailColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: AppColors.mutedText.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.teacher,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          course.priceLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${course.durationHours} hours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warmAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCourseState extends StatelessWidget {
  const _EmptyCourseState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No courses found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filter settings.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseLoadingState extends StatelessWidget {
  const _CourseLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
