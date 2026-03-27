import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/course_catalog_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<CourseCatalogItem> get _filteredCourses {
    final query = _searchController.text.trim().toLowerCase();

    return courseCatalogItems.where((course) {
      final matchesCategory =
          _selectedCategory == 'All' || course.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.teacher.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<CourseCatalogItem> get _featuredCourses {
    return courseCatalogItems
        .where((course) => course.isPopular || course.isNew)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCourse(CourseCatalogItem course) {
    if (course.opensProductDetail) {
      Get.toNamed(AppRoutes.productDesignCourse);
      return;
    }

    Get.snackbar(
      course.title,
      'Is course detail ko hum next API step me open kara denge.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  void _applySuggestion(String suggestion) {
    _searchController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCourses = _filteredCourses;
    final showSuggestedLayout = _searchController.text.trim().isEmpty;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search courses, teacher, category',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.trim().isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...['All', ...courseFilterCategories].map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _SearchCategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onTap: () => setState(() {
                            _selectedCategory = category;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (showSuggestedLayout) ...[
                Text(
                  'Popular searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: courseSearchSuggestions.map((suggestion) {
                    return _SearchSuggestionChip(
                      label: suggestion,
                      onTap: () => _applySuggestion(suggestion),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Featured courses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ..._featuredCourses.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SearchCourseCard(
                      course: course,
                      onTap: () => _openCourse(course),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Text(
                      'Results',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredCourses.length} found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filteredCourses.isEmpty)
                  const _SearchEmptyState()
                else
                  ...filteredCourses.map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SearchCourseCard(
                        course: course,
                        onTap: () => _openCourse(course),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCategoryChip extends StatelessWidget {
  const _SearchCategoryChip({
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF5F6FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppColors.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SearchCourseCard extends StatelessWidget {
  const _SearchCourseCard({required this.course, required this.onTap});

  final CourseCatalogItem course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: course.thumbnailColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (course.isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warmAccent.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Popular',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warmAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.teacher,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '\$${course.price}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.durationHours}h',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No courses found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another keyword, teacher name, or category.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
