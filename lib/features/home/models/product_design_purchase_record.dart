class ProductDesignPurchaseRecord {
  const ProductDesignPurchaseRecord({
    required this.isPurchased,
    this.purchaseId = '',
    this.purchasedAt,
  });

  const ProductDesignPurchaseRecord.empty()
      : isPurchased = false,
        purchaseId = '',
        purchasedAt = null;

  final bool isPurchased;
  final String purchaseId;
  final DateTime? purchasedAt;

  ProductDesignPurchaseRecord copyWith({
    bool? isPurchased,
    String? purchaseId,
    DateTime? purchasedAt,
    bool clearPurchasedAt = false,
  }) {
    return ProductDesignPurchaseRecord(
      isPurchased: isPurchased ?? this.isPurchased,
      purchaseId: purchaseId ?? this.purchaseId,
      purchasedAt: clearPurchasedAt ? null : purchasedAt ?? this.purchasedAt,
    );
  }
}
