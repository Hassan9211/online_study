import 'package:flutter/material.dart';

class CourseCatalogItem {
  const CourseCatalogItem({
    required this.title,
    required this.teacher,
    required this.price,
    required this.durationHours,
    required this.category,
    required this.thumbnailColor,
    this.isPopular = false,
    this.isNew = false,
    this.opensProductDetail = false,
  });

  final String title;
  final String teacher;
  final int price;
  final int durationHours;
  final String category;
  final Color thumbnailColor;
  final bool isPopular;
  final bool isNew;
  final bool opensProductDetail;
}

const List<CourseCatalogItem> courseCatalogItems = [
  CourseCatalogItem(
    title: 'Product Design v1.0',
    teacher: 'Robertson Connie',
    price: 190,
    durationHours: 16,
    category: 'Design',
    thumbnailColor: Color(0xFFCBCBCB),
    isPopular: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    title: 'Product Design',
    teacher: 'Webb Landon',
    price: 250,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFD1D1D1),
    isPopular: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    title: 'Product Design',
    teacher: 'Webb Kyle',
    price: 250,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFD4D4D4),
    isNew: true,
    opensProductDetail: true,
  ),
  CourseCatalogItem(
    title: 'Java Development',
    teacher: 'Nguyen Shane',
    price: 190,
    durationHours: 16,
    category: 'Coding',
    thumbnailColor: Color(0xFFD3D3D3),
    isPopular: true,
  ),
  CourseCatalogItem(
    title: 'Writing Essentials',
    teacher: 'Avery Watson',
    price: 130,
    durationHours: 8,
    category: 'Writing',
    thumbnailColor: Color(0xFFD7D7D7),
  ),
  CourseCatalogItem(
    title: 'Visual Design',
    teacher: 'Bert Pullman',
    price: 250,
    durationHours: 14,
    category: 'Visual identity',
    thumbnailColor: Color(0xFFCFCFCF),
    isNew: true,
  ),
  CourseCatalogItem(
    title: 'Painting Basics',
    teacher: 'Elisa Romeo',
    price: 140,
    durationHours: 8,
    category: 'Painting',
    thumbnailColor: Color(0xFFD6D6D6),
    isNew: true,
  ),
  CourseCatalogItem(
    title: 'Music Theory',
    teacher: 'David Rowen',
    price: 120,
    durationHours: 6,
    category: 'Music',
    thumbnailColor: Color(0xFFD8D8D8),
  ),
  CourseCatalogItem(
    title: 'Mathematics Logic',
    teacher: 'Henry Collins',
    price: 160,
    durationHours: 20,
    category: 'Mathematics',
    thumbnailColor: Color(0xFFCDCDCD),
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
