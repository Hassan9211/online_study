class SupportRequestRecord {
  const SupportRequestRecord({
    required this.id,
    required this.topic,
    required this.subject,
    required this.message,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String topic;
  final String subject;
  final String message;
  final String email;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'topic': topic,
      'subject': subject,
      'message': message,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
