import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import '../models/product_design_purchase_record.dart';
import 'product_design_purchase_repository.dart';

class LocalProductDesignPurchaseRepository
    implements ProductDesignPurchaseRepository {
  static const String _isPurchasedKey = 'product_design_is_purchased';
  static const String _purchaseIdKey = 'product_design_purchase_id';
  static const String _purchasedAtKey = 'product_design_purchased_at';
  static const String _paymentMethodsKey = 'product_design_payment_methods';

  @override
  Future<ProductDesignPurchaseRecord> loadCachedPurchase() => loadPurchase();

  @override
  Future<ProductDesignPurchaseRecord> loadPurchase() async {
    final preferences = await SharedPreferences.getInstance();
    final purchasedAtRaw = preferences.getString(_purchasedAtKey);

    return ProductDesignPurchaseRecord(
      isPurchased: preferences.getBool(_isPurchasedKey) ?? false,
      purchaseId: preferences.getString(_purchaseIdKey) ?? '',
      purchasedAt: purchasedAtRaw == null
          ? null
          : DateTime.tryParse(purchasedAtRaw),
    );
  }

  @override
  Future<void> savePurchase(ProductDesignPurchaseRecord record) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_isPurchasedKey, record.isPurchased);
    await preferences.setString(_purchaseIdKey, record.purchaseId);

    if (record.purchasedAt == null) {
      await preferences.remove(_purchasedAtKey);
    } else {
      await preferences.setString(
        _purchasedAtKey,
        record.purchasedAt!.toIso8601String(),
      );
    }
  }

  @override
  Future<void> clearCachedState() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_isPurchasedKey);
    await preferences.remove(_purchaseIdKey);
    await preferences.remove(_purchasedAtKey);
    await preferences.remove(_paymentMethodsKey);
  }

  @override
  Future<List<PaymentMethodRecord>> loadPaymentMethods() async {
    final preferences = await SharedPreferences.getInstance();
    final rawMethods = preferences.getString(_paymentMethodsKey);
    if (rawMethods == null || rawMethods.trim().isEmpty) {
      return const <PaymentMethodRecord>[];
    }

    try {
      final decoded = jsonDecode(rawMethods);
      if (decoded is! List) {
        return const <PaymentMethodRecord>[];
      }

      final methods = decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return PaymentMethodRecord(
          id: (map['id'] ?? '').toString(),
          label: (map['label'] ?? 'Card').toString(),
          maskedNumber: (map['maskedNumber'] ?? '').toString(),
        );
      }).where((method) {
        return method.id.trim().isNotEmpty && method.label.trim().isNotEmpty;
      }).toList();

      return methods;
    } catch (_) {
      return const <PaymentMethodRecord>[];
    }
  }

  Future<void> savePaymentMethods(List<PaymentMethodRecord> methods) async {
    if (methods.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _paymentMethodsKey,
      jsonEncode(
        methods.map((method) {
          return <String, dynamic>{
            'id': method.id,
            'label': method.label,
            'maskedNumber': method.maskedNumber,
          };
        }).toList(),
      ),
    );
  }

  @override
  Future<String> createCheckout({
    required PaymentCheckoutRequest request,
  }) async {
    return 'local_${request.paymentMethodId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<ProductDesignPurchaseRecord> verifyPin({
    required String paymentId,
    required String pin,
  }) async {
    final record = ProductDesignPurchaseRecord(
      isPurchased: true,
      purchaseId: paymentId,
      purchasedAt: DateTime.now(),
    );
    await savePurchase(record);
    return record;
  }
}
