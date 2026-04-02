class CoursePurchaseRecord {
  const CoursePurchaseRecord({
    required this.courseId,
    required this.courseTitle,
    required this.isPurchased,
    this.purchaseId = '',
    this.purchasedAt,
  });

  const CoursePurchaseRecord.empty({
    this.courseId = '',
    this.courseTitle = '',
  }) : isPurchased = false,
       purchaseId = '',
       purchasedAt = null;

  final String courseId;
  final String courseTitle;
  final bool isPurchased;
  final String purchaseId;
  final DateTime? purchasedAt;

  bool matches({
    String id = '',
    String title = '',
  }) {
    final normalizedId = id.trim().toLowerCase();
    final normalizedTitle = _normalizeKey(title);

    if (normalizedId.isNotEmpty &&
        normalizedId == courseId.trim().toLowerCase()) {
      return true;
    }

    if (normalizedTitle.isNotEmpty &&
        normalizedTitle == _normalizeKey(courseTitle)) {
      return true;
    }

    return false;
  }

  CoursePurchaseRecord copyWith({
    String? courseId,
    String? courseTitle,
    bool? isPurchased,
    String? purchaseId,
    DateTime? purchasedAt,
    bool clearPurchasedAt = false,
  }) {
    return CoursePurchaseRecord(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      isPurchased: isPurchased ?? this.isPurchased,
      purchaseId: purchaseId ?? this.purchaseId,
      purchasedAt: clearPurchasedAt ? null : purchasedAt ?? this.purchasedAt,
    );
  }
}

String _normalizeKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
