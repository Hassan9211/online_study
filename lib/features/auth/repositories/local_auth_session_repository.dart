import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_record.dart';
import 'auth_session_repository.dart';

class LocalAuthSessionRepository implements AuthSessionRepository {
  static const String _isLoggedInKey = 'auth_is_logged_in';
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';
  static const String _userIdKey = 'auth_user_id';
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  @override
  Future<AuthSessionRecord> loadSession() async {
    final preferences = await SharedPreferences.getInstance();

    return AuthSessionRecord(
      isLoggedIn: preferences.getBool(_isLoggedInKey) ?? false,
      email: preferences.getString(_emailKey) ?? '',
      password: preferences.getString(_passwordKey) ?? '',
      userId: preferences.getString(_userIdKey) ?? '',
      accessToken: preferences.getString(_accessTokenKey) ?? '',
      refreshToken: preferences.getString(_refreshTokenKey) ?? '',
    );
  }

  @override
  Future<void> saveSession(AuthSessionRecord session) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_isLoggedInKey, session.isLoggedIn);
    await preferences.setString(_emailKey, session.email);
    await preferences.setString(_passwordKey, session.password);
    await preferences.setString(_userIdKey, session.userId);
    await preferences.setString(_accessTokenKey, session.accessToken);
    await preferences.setString(_refreshTokenKey, session.refreshToken);
  }

  @override
  Future<void> sendOtp({required String phone}) async {}

  @override
  Future<void> verifyOtp({required String phone, required String code}) async {}

  @override
  Future<AuthSessionRecord> signUp({
    required String email,
    required String password,
    required String phone,
    required bool termsAccepted,
  }) async {
    if (!termsAccepted) {
      throw Exception('Terms accept karna zaroori hai.');
    }

    final session = AuthSessionRecord(
      isLoggedIn: true,
      email: email.trim(),
      password: password.trim(),
      userId: 'local_${DateTime.now().millisecondsSinceEpoch}',
    );
    await saveSession(session);
    return session;
  }

  @override
  Future<AuthSessionRecord> logIn({
    required String email,
    required String password,
  }) async {
    final session = await loadSession();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (session.email.trim().toLowerCase() != normalizedEmail ||
        session.password != normalizedPassword) {
      throw Exception('Email ya password match nahi kar raha.');
    }

    final updatedSession = session.copyWith(
      email: email.trim(),
      password: normalizedPassword,
      isLoggedIn: true,
    );
    await saveSession(updatedSession);
    return updatedSession;
  }

  @override
  Future<AuthSessionRecord> changePassword({
    required AuthSessionRecord session,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (session.password.trim() != currentPassword.trim()) {
      throw Exception('Current password sahi nahi hai.');
    }

    final updatedSession = session.copyWith(password: newPassword.trim());
    await saveSession(updatedSession);
    return updatedSession;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final session = await loadSession();
    if (session.email.trim().toLowerCase() == email.trim().toLowerCase()) {
      await saveSession(session.copyWith(password: newPassword.trim()));
    }
  }

  @override
  Future<void> logOut({required AuthSessionRecord session}) async {}
}
