import 'course_price_display.dart';

class CourseLessonRecord {
  const CourseLessonRecord({
    required this.id,
    required this.title,
    required this.durationLabel,
    this.description = '',
    this.videoUrl = '',
    this.isLocked = false,
    this.isCompleted = false,
    this.positionSeconds = 0,
  });

  final String id;
  final String title;
  final String durationLabel;
  final String description;
  final String videoUrl;
  final bool isLocked;
  final bool isCompleted;
  final int positionSeconds;
}

class CourseDetailRecord {
  const CourseDetailRecord({
    required this.id,
    required this.title,
    required this.teacher,
    required this.price,
    required this.durationHours,
    required this.category,
    required this.lessonCount,
    required this.description,
    required this.lessons,
    this.isPopular = false,
    this.isNew = false,
    this.isFavourite = false,
    this.isPurchased = true,
  });

  final String id;
  final String title;
  final String teacher;
  final int price;
  final int durationHours;
  final String category;
  final int lessonCount;
  final String description;
  final List<CourseLessonRecord> lessons;
  final bool isPopular;
  final bool isNew;
  final bool isFavourite;
  final bool isPurchased;

  int get displayPrice => displayCoursePrice(price);
  String get priceLabel => displayCoursePriceLabel(price);

  String get metaLabel {
    final resolvedLessonCount = lessons.isEmpty ? lessonCount : lessons.length;
    if (durationHours > 0) {
      return '$durationHours hours - $resolvedLessonCount Lessons';
    }
    return '$resolvedLessonCount Lessons';
  }

  CourseDetailRecord copyWith({
    bool? isFavourite,
    bool? isPurchased,
    List<CourseLessonRecord>? lessons,
  }) {
    return CourseDetailRecord(
      id: id,
      title: title,
      teacher: teacher,
      price: price,
      durationHours: durationHours,
      category: category,
      lessonCount: lessonCount,
      description: description,
      lessons: lessons ?? this.lessons,
      isPopular: isPopular,
      isNew: isNew,
      isFavourite: isFavourite ?? this.isFavourite,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
