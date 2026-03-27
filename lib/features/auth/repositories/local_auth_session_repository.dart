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
}
