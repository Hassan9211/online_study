import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../models/support_request_record.dart';
import 'support_repository.dart';

class RemoteSupportRepository implements SupportRepository {
  RemoteSupportRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<SupportRequestRecord> submitRequest({
    required String topic,
    required String subject,
    required String message,
    required String email,
  }) async {
    final body = await _apiClient.postJson(
      ApiEndpoints.support.tickets,
      body: <String, dynamic>{
        'topic': topic,
        'subject': subject,
        'message': message,
        'email': email,
      },
    );

    final payload = asMap(unwrapBody(body, keys: const ['data', 'ticket']));
    return SupportRequestRecord(
      id: readString(
        payload,
        const ['id', 'ticket_id'],
        fallback: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      ),
      topic: readString(payload, const ['topic'], fallback: topic),
      subject: readString(payload, const ['subject'], fallback: subject),
      message: readString(
        payload,
        const ['message', 'body'],
        fallback: message,
      ),
      email: readString(payload, const ['email'], fallback: email),
      createdAt:
          readDateTime(payload, const ['created_at', 'timestamp']) ??
          DateTime.now(),
    );
  }
}
