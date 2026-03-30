class PaymentMethodRecord {
  const PaymentMethodRecord({
    required this.id,
    required this.label,
    required this.maskedNumber,
  });

  final String id;
  final String label;
  final String maskedNumber;
}
