import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/support_request_record.dart';
import 'support_repository.dart';

class LocalSupportRepository implements SupportRepository {
  static const String _supportRequestsKey = 'support_requests';

  @override
  Future<SupportRequestRecord> submitRequest({
    required String topic,
    required String subject,
    required String message,
    required String email,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final savedRaw = preferences.getString(_supportRequestsKey);
    final savedList = savedRaw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(savedRaw) as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

    final record = SupportRequestRecord(
      id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      topic: topic,
      subject: subject,
      message: message,
      email: email,
      createdAt: DateTime.now(),
    );

    savedList.insert(0, record.toMap());
    await preferences.setString(_supportRequestsKey, jsonEncode(savedList));
    return record;
  }
}
