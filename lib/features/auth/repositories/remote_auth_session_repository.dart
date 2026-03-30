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
  Future<void> sendOtp({required String phone}) async {
    await _apiClient.postJson(
      ApiEndpoints.auth.sendOtp,
      body: <String, dynamic>{
        'phone': phone,
        'phone_number': phone,
      },
    );
  }

  @override
  Future<void> verifyOtp({required String phone, required String code}) async {
    await _apiClient.postJson(
      ApiEndpoints.auth.verifyOtp,
      body: <String, dynamic>{
        'phone': phone,
        'phone_number': phone,
        'otp': code,
        'code': code,
      },
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
        'full_name': displayName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'confirm_password': password,
        'phone': phone,
        'phone_number': phone,
        'terms_accepted': termsAccepted,
        'termsAccepted': termsAccepted,
        'terms': termsAccepted,
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
        'password': newPassword,
        'password_confirmation': newPassword,
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
        '/forgot-password',
      ],
      body: <String, dynamic>{'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _postJsonWithFallbacks(
      <String>[
        ApiEndpoints.auth.resetPassword,
        '/reset-password',
      ],
      body: <String, dynamic>{
        'email': email,
        'token': token,
        'otp': token,
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

    throw const ApiException('Forgot password request complete nahi ho saki.');
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
    final payload = root.containsKey('user') || root.containsKey('session')
        ? root
        : asMap(unwrapBody(body, keys: const ['data', 'result']));
    final user = readMap(payload, const ['user', 'account', 'profile']);
    final session = readMap(payload, const ['session', 'tokens', 'token']);

    final accessToken = readString(
      session,
      const [
        'accessToken',
        'access_token',
        'token',
        'plainTextToken',
        'plain_text_token',
        'bearer_token',
      ],
      fallback: readString(
        payload,
        const [
          'accessToken',
          'access_token',
          'token',
          'plainTextToken',
          'plain_text_token',
          'bearer_token',
        ],
      ),
    );
    final refreshToken = readString(
      session,
      const ['refreshToken', 'refresh_token'],
      fallback: readString(payload, const ['refreshToken', 'refresh_token']),
    );
    final userId = readString(
      user,
      const ['id', 'user_id'],
      fallback: readString(payload, const ['user_id', 'id']),
    );
    final email = readString(
      user,
      const ['email'],
      fallback: fallbackEmail.trim(),
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
}
