import 'package:flutter/material.dart';

import 'course_price_display.dart';

class CourseCatalogItem {
  const CourseCatalogItem({
    this.id = '',
    required this.title,
    required this.teacher,
    required this.price,
    required this.durationHours,
    required this.category,
    required this.thumbnailColor,
    this.lessonCount = 0,
    this.shortDescription = '',
    this.isPopular = false,
    this.isNew = false,
    this.isFavourite = false,
    this.opensProductDetail = false,
  });

  final String id;
  final String title;
  final String teacher;
  final int price;
  final int durationHours;
  final String category;
  final Color thumbnailColor;
  final int lessonCount;
  final String shortDescription;
  final bool isPopular;
  final bool isNew;
  final bool isFavourite;
  final bool opensProductDetail;

  int get displayPrice => displayCoursePrice(price);
  String get priceLabel => displayCoursePriceLabel(price);

  CourseCatalogItem copyWith({
    String? id,
    String? title,
    String? teacher,
    int? price,
    int? durationHours,
    String? category,
    Color? thumbnailColor,
    int? lessonCount,
    String? shortDescription,
    bool? isPopular,
    bool? isNew,
    bool? isFavourite,
    bool? opensProductDetail,
  }) {
    return CourseCatalogItem(
      id: id ?? this.id,
      title: title ?? this.title,
      teacher: teacher ?? this.teacher,
      price: price ?? this.price,
      durationHours: durationHours ?? this.durationHours,
      category: category ?? this.category,
      thumbnailColor: thumbnailColor ?? this.thumbnailColor,
      lessonCount: lessonCount ?? this.lessonCount,
      shortDescription: shortDescription ?? this.shortDescription,
      isPopular: isPopular ?? this.isPopular,
      isNew: isNew ?? this.isNew,
      isFavourite: isFavourite ?? this.isFavourite,
      opensProductDetail: opensProductDetail ?? this.opensProductDetail,
    );
  }
}

const List<CourseCatalogItem> courseCatalogItems = [
  CourseCatalogItem(
    id: '1',
    title: 'Product Design v1.0',
    teacher: 'Robertson Connie',
    price: 74,
    durationHours: 16,
    category: 'Design',
    thumbnailColor: Color(0xFFCBCBCB),
    lessonCount: 9,
    shortDescription: 'Learn product design from research to handoff.',
    isPopular: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    id: 'product_design_webb_landon',
    title: 'Product Design',
    teacher: 'Webb Landon',
    price: 74,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFD1D1D1),
    lessonCount: 12,
    shortDescription: 'Practical product design principles and exercises.',
    isPopular: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    id: 'product_design_webb_kyle',
    title: 'Product Design',
    teacher: 'Webb Kyle',
    price: 74,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFD4D4D4),
    lessonCount: 12,
    shortDescription: 'A modern UI and product design learning path.',
    isNew: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    id: 'java_development',
    title: 'Java Development',
    teacher: 'Nguyen Shane',
    price: 100,
    durationHours: 5,
    category: 'Coding',
    thumbnailColor: Color(0xFFD3D3D3),
    lessonCount: 5,
    shortDescription: 'Core Java video lessons for app and backend work.',
    isPopular: true,
  ),
  CourseCatalogItem(
    id: 'writing_essentials',
    title: 'Writing Essentials',
    teacher: 'Avery Watson',
    price: 100,
    durationHours: 8,
    category: 'Writing',
    thumbnailColor: Color(0xFFD7D7D7),
    lessonCount: 10,
    shortDescription: 'Improve structure, clarity, and editing skills.',
  ),
  CourseCatalogItem(
    id: 'visual_design',
    title: 'Visual Design',
    teacher: 'Bert Pullman',
    price: 100,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFCFCFCF),
    lessonCount: 16,
    shortDescription: 'Visual hierarchy, color, and composition basics.',
    isNew: true,
  ),
  CourseCatalogItem(
    id: 'painting_basics',
    title: 'Painting Basics',
    teacher: 'Elisa Romeo',
    price: 100,
    durationHours: 8,
    category: 'Painting',
    thumbnailColor: Color(0xFFD6D6D6),
    lessonCount: 11,
    shortDescription: 'A guided introduction to painting fundamentals.',
    isNew: true,
  ),
  CourseCatalogItem(
    id: 'music_theory',
    title: 'Music Theory',
    teacher: 'David Rowen',
    price: 100,
    durationHours: 6,
    category: 'Music',
    thumbnailColor: Color(0xFFD8D8D8),
    lessonCount: 8,
    shortDescription: 'Learn rhythm, scales, and harmony essentials.',
  ),
  CourseCatalogItem(
    id: 'mathematics_logic',
    title: 'Mathematics Logic',
    teacher: 'Henry Collins',
    price: 100,
    durationHours: 20,
    category: 'Mathematics',
    thumbnailColor: Color(0xFFCDCDCD),
    lessonCount: 24,
    shortDescription: 'Strengthen logic, proofs, and problem solving.',
  ),
];

const List<String> courseFilterCategories = [
  'Design',
  'Painting',
  'Coding',
  'Music',
  'Visual identity',
  'Mathematics',
];

const List<String> courseSearchSuggestions = [
  'Visual identity',
  'Painting',
  'Coding',
  'Writing',
];

const List<String> courseDurationOptions = [
  '3-8 Hours',
  '8-14 Hours',
  '14-20 Hours',
  '20-24 Hours',
  '24-30 Hours',
];

(int, int)? courseDurationRangeFor(String? label) {
  return switch (label) {
    '3-8 Hours' => (3, 8),
    '8-14 Hours' => (8, 14),
    '14-20 Hours' => (14, 20),
    '20-24 Hours' => (20, 24),
    '24-30 Hours' => (24, 30),
    _ => null,
  };
}
