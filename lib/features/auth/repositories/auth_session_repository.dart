import '../models/auth_session_record.dart';

abstract interface class AuthSessionRepository {
  Future<AuthSessionRecord> loadSession();
  Future<void> saveSession(AuthSessionRecord session);
  Future<void> sendOtp({String email = '', String phone = ''});
  Future<AuthSessionRecord?> verifyOtp({
    String email = '',
    String phone = '',
    required String code,
    String fallbackEmail = '',
    String fallbackPassword = '',
  });
  Future<AuthSessionRecord> signUp({
    required String email,
    required String password,
    required String phone,
    required bool termsAccepted,
  });
  Future<AuthSessionRecord> logIn({
    required String email,
    required String password,
  });
  Future<AuthSessionRecord> changePassword({
    required AuthSessionRecord session,
    required String currentPassword,
    required String newPassword,
  });
  Future<void> requestPasswordReset({required String email});
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<void> logOut({required AuthSessionRecord session});
}
