class PaymentCheckoutRequest {
  const PaymentCheckoutRequest({
    required this.paymentMethodId,
    required this.paymentMethodLabel,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.amountValue,
    required this.amountLabel,
    required this.currencyCode,
  });

  final String paymentMethodId;
  final String paymentMethodLabel;
  final String cardholderName;
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final double amountValue;
  final String amountLabel;
  final String currencyCode;

  String get normalizedCardNumber => cardNumber.replaceAll(RegExp(r'\D'), '');
  String get normalizedExpiryMonth => expiryMonth.padLeft(2, '0');
  String get normalizedExpiryYear => expiryYear.padLeft(2, '0');
  String get normalizedCvv => cvv.replaceAll(RegExp(r'\D'), '');
  String get expiryDate => '$normalizedExpiryMonth/$normalizedExpiryYear';
  double get normalizedAmountValue {
    if (!amountValue.isFinite || amountValue.isNaN || amountValue < 0) {
      return 0;
    }

    return double.parse(amountValue.toStringAsFixed(2));
  }

  Map<String, dynamic> toMap({required String courseId}) {
    return <String, dynamic>{
      'course_id': courseId,
      'payment_method_id': paymentMethodId,
      'payment_method_label': paymentMethodLabel,
      'cardholder_name': cardholderName.trim(),
      'card_number': normalizedCardNumber,
      'expiry_month': normalizedExpiryMonth,
      'expiry_year': normalizedExpiryYear,
      'expiry_date': expiryDate,
      'cvv': normalizedCvv,
      'amount': normalizedAmountValue,
      'currency': currencyCode,
    };
  }
}
