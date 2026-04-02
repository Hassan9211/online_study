class MyCourseRecord {
  const MyCourseRecord({
    required this.id,
    required this.title,
    required this.displayTitle,
    required this.completedCount,
    required this.totalCount,
  });

  final String id;
  final String title;
  final String displayTitle;
  final int completedCount;
  final int totalCount;
}
