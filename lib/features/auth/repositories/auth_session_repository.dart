import '../models/auth_session_record.dart';

abstract interface class AuthSessionRepository {
  Future<AuthSessionRecord> loadSession();
  Future<void> saveSession(AuthSessionRecord session);
}
