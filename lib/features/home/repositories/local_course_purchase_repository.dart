import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_purchase_record.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';
import 'course_purchase_repository.dart';

class LocalCoursePurchaseRepository implements CoursePurchaseRepository {
  static const String _purchasesKey = 'course_purchase_records';
  static const String _paymentMethodsKey = 'course_purchase_payment_methods';

  @override
  Future<List<CoursePurchaseRecord>> loadCachedPurchases() => loadPurchases();

  @override
  Future<List<CoursePurchaseRecord>> loadPurchases() async {
    final preferences = await SharedPreferences.getInstance();
    final rawPurchases = preferences.getString(_purchasesKey);
    if (rawPurchases == null || rawPurchases.trim().isEmpty) {
      return const <CoursePurchaseRecord>[];
    }

    try {
      final decoded = jsonDecode(rawPurchases);
      if (decoded is! List) {
        return const <CoursePurchaseRecord>[];
      }

      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final purchasedAtRaw = (map['purchased_at'] ?? '').toString();
        return CoursePurchaseRecord(
          courseId: (map['course_id'] ?? '').toString(),
          courseTitle: (map['course_title'] ?? '').toString(),
          isPurchased: map['is_purchased'] == true,
          purchaseId: (map['purchase_id'] ?? '').toString(),
          purchasedAt: purchasedAtRaw.isEmpty
              ? null
              : DateTime.tryParse(purchasedAtRaw),
        );
      }).where((record) {
        return record.courseId.trim().isNotEmpty ||
            record.courseTitle.trim().isNotEmpty;
      }).toList();
    } catch (_) {
      return const <CoursePurchaseRecord>[];
    }
  }

  @override
  Future<void> savePurchase(CoursePurchaseRecord record) async {
    final purchases = await loadPurchases();
    final nextPurchases = <CoursePurchaseRecord>[
      record,
      ...purchases.where((item) {
        return !item.matches(id: record.courseId, title: record.courseTitle);
      }),
    ];

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _purchasesKey,
      jsonEncode(
        nextPurchases.map((item) {
          return <String, dynamic>{
            'course_id': item.courseId,
            'course_title': item.courseTitle,
            'is_purchased': item.isPurchased,
            'purchase_id': item.purchaseId,
            'purchased_at': item.purchasedAt?.toIso8601String(),
          };
        }).toList(),
      ),
    );
  }

  @override
  Future<void> clearCachedState() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_purchasesKey);
    await preferences.remove(_paymentMethodsKey);
  }

  Future<void> savePurchases(List<CoursePurchaseRecord> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _purchasesKey,
      jsonEncode(
        records.map((item) {
          return <String, dynamic>{
            'course_id': item.courseId,
            'course_title': item.courseTitle,
            'is_purchased': item.isPurchased,
            'purchase_id': item.purchaseId,
            'purchased_at': item.purchasedAt?.toIso8601String(),
          };
        }).toList(),
      ),
    );
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
    required String courseId,
    required PaymentCheckoutRequest request,
  }) async {
    return 'local_${courseId}_${request.paymentMethodId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<CoursePurchaseRecord> verifyPin({
    required String courseId,
    required String courseTitle,
    required String paymentId,
    required String pin,
  }) async {
    final record = CoursePurchaseRecord(
      courseId: courseId,
      courseTitle: courseTitle,
      isPurchased: true,
      purchaseId: paymentId,
      purchasedAt: DateTime.now(),
    );
    await savePurchase(record);
    return record;
  }
}
