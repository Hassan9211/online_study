import '../models/support_request_record.dart';

abstract interface class SupportRepository {
  Future<SupportRequestRecord> submitRequest({
    required String topic,
    required String subject,
    required String message,
    required String email,
  });
}
