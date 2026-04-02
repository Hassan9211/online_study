import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../models/auth_session_record.dart';
import 'auth_session_repository.dart';
import 'local_auth_session_repository.dart';

class RemoteAuthSessionRepository implements AuthSessionRepository {
  RemoteAuthSessionRepository(this._apiClient, this._localStore);

  final ApiClient _apiClient;
  final LocalAuthSessionRepository _localStore;

  @override
  Future<AuthSessionRecord> loadSession() => _localStore.loadSession();

  @override
  Future<void> saveSession(AuthSessionRecord session) {
    return _localStore.saveSession(session);
  }

  @override
  Future<void> sendOtp({String email = '', String phone = ''}) async {
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    if (normalizedEmail.isEmpty && normalizedPhone.isEmpty) {
      throw const ApiException('Email or phone is required.');
    }

    final body = await _apiClient.postJson(
      ApiEndpoints.auth.sendOtp,
      body: <String, dynamic>{
        if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
        if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
      },
    );
    _logAuthDebug('OTP send response -> $body');
  }

  @override
  Future<AuthSessionRecord?> verifyOtp({
    String email = '',
    String phone = '',
    required String code,
    String fallbackEmail = '',
    String fallbackPassword = '',
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    if (normalizedEmail.isEmpty && normalizedPhone.isEmpty) {
      throw const ApiException('Email or phone is required.');
    }

    final body = await _apiClient.postJson(
      ApiEndpoints.auth.verifyOtp,
      body: <String, dynamic>{
        if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
        if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
        'code': code,
        'otp': code,
        'otp_code': code,
        'otpCode': code,
        'verification_code': code,
      },
    );
    _logAuthDebug('OTP verify response -> $body');

    return _tryParseVerifiedSession(
      body,
      fallbackEmail: fallbackEmail.isEmpty ? normalizedEmail : fallbackEmail,
      fallbackPassword: fallbackPassword,
    );
  }

  @override
  Future<AuthSessionRecord> signUp({
    required String email,
    required String password,
    required String phone,
    required bool termsAccepted,
  }) async {
    final displayName = _deriveDisplayName(email);

    final body = await _apiClient.postJson(
      ApiEndpoints.auth.signUp,
      body: <String, dynamic>{
        'name': displayName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'phone': phone,
        'terms_accepted': termsAccepted,
      },
    );

    final session = _parseSession(
      body,
      fallbackEmail: email,
      fallbackPassword: password,
    );

    if (session.accessToken.trim().isEmpty) {
      return logIn(email: email, password: password);
    }

    await saveSession(session);
    return session;
  }

  @override
  Future<AuthSessionRecord> logIn({
    required String email,
    required String password,
  }) async {
    final body = await _apiClient.postJson(
      ApiEndpoints.auth.logIn,
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    final session = _parseSession(
      body,
      fallbackEmail: email,
      fallbackPassword: password,
    );
    await saveSession(session);
    return session;
  }

  @override
  Future<AuthSessionRecord> changePassword({
    required AuthSessionRecord session,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.postJson(
      ApiEndpoints.auth.changePassword,
      body: <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
    final updatedSession = session.copyWith(password: newPassword.trim());
    await saveSession(updatedSession);
    return updatedSession;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await _postJsonWithFallbacks(
      <String>[
        ApiEndpoints.auth.forgotPassword,
        ApiEndpoints.auth.forgotPasswordCompat,
      ],
      body: <String, dynamic>{'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _postJsonWithFallbacks(
      <String>[
        ApiEndpoints.auth.resetPassword,
        ApiEndpoints.auth.resetPasswordCompat,
      ],
      body: <String, dynamic>{
        'email': email,
        'code': code,
        'token': code,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );

    final localSession = await _localStore.loadSession();
    if (localSession.email.trim().toLowerCase() == email.trim().toLowerCase()) {
      await saveSession(localSession.copyWith(password: newPassword.trim()));
    }
  }

  Future<dynamic> _postJsonWithFallbacks(
    List<String> paths, {
    required Map<String, dynamic> body,
  }) async {
    ApiException? lastNotFound;

    for (final path in paths) {
      try {
        return await _apiClient.postJson(path, body: body);
      } on ApiException catch (error) {
        if (error.statusCode == 404) {
          lastNotFound = error;
          continue;
        }
        rethrow;
      }
    }

    if (lastNotFound != null) {
      throw lastNotFound;
    }

    throw const ApiException(
      'The request could not be completed.',
    );
  }

  @override
  Future<void> logOut({required AuthSessionRecord session}) async {
    await _apiClient.postJson(
      ApiEndpoints.auth.logOut,
      body: <String, dynamic>{},
    );
  }

  AuthSessionRecord _parseSession(
    dynamic body, {
    required String fallbackEmail,
    required String fallbackPassword,
  }) {
    final root = asMap(body);
    final payload = asMap(unwrapBody(body));
    final source = payload.isEmpty ? root : payload;
    final user = readMap(source, const ['user']);
    final session = readMap(source, const ['session']);

    final accessToken = readString(
      session,
      const ['accessToken', 'access_token', 'token'],
      fallback: readString(
        source,
        const ['accessToken', 'access_token', 'token'],
      ),
    );
    final refreshToken = readString(
      session,
      const ['refreshToken', 'refresh_token'],
      fallback: readString(source, const ['refreshToken', 'refresh_token']),
    );
    final userId = readString(
      user,
      const ['id', 'user_id'],
      fallback: readString(source, const ['user_id', 'id']),
    );
    final email = readString(
      user,
      const ['email'],
      fallback: readString(source, const ['email'], fallback: fallbackEmail.trim()),
    );

    return AuthSessionRecord(
      isLoggedIn: true,
      email: email,
      password: fallbackPassword.trim(),
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  AuthSessionRecord? _tryParseVerifiedSession(
    dynamic body, {
    required String fallbackEmail,
    required String fallbackPassword,
  }) {
    final session = _parseSession(
      body,
      fallbackEmail: fallbackEmail,
      fallbackPassword: fallbackPassword,
    );

    if (session.accessToken.trim().isEmpty) {
      return null;
    }

    return session;
  }

  String _deriveDisplayName(String email) {
    final localPart = email.trim().split('@').first;
    if (localPart.isEmpty) {
      return 'Learner';
    }

    final words = localPart
        .split(RegExp(r'[._\-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final cleaned = part.trim();
          return cleaned[0].toUpperCase() + cleaned.substring(1);
        })
        .toList();

    if (words.isEmpty) {
      return 'Learner';
    }

    return words.join(' ');
  }

  void _logAuthDebug(String message) {
    if (kDebugMode) {
      debugPrint('Auth debug -> $message');
    }
  }
}
