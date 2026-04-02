import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/profile_record.dart';
import 'local_profile_repository.dart';
import 'profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalProfileRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<ProfileRecord> loadCachedProfile() {
    return _localStore.loadProfile();
  }

  @override
  Future<ProfileRecord> saveCachedProfile(ProfileRecord profile) {
    return _localStore.saveProfile(profile);
  }

  @override
  Future<void> clearCachedProfile() {
    return _localStore.clearCachedProfile();
  }

  @override
  Future<ProfileRecord> loadProfile() async {
    final cachedProfile = await _localStore.loadProfile();
    if (!await _hasAccessToken()) {
      return cachedProfile;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.me);
      final remoteProfile = _parseProfile(body, fallback: cachedProfile);
      return _localStore.saveProfile(remoteProfile);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return cachedProfile;
    } catch (_) {
      return cachedProfile;
    }
  }

  @override
  Future<ProfileRecord> saveProfile(ProfileRecord profile) async {
    if (!await _hasAccessToken()) {
      return _localStore.saveProfile(profile);
    }

    final payload = <String, dynamic>{
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'bio': profile.bio,
    };

    try {
      final body = await _submitProfileUpdate(payload);
      final savedProfile = _parseProfile(body, fallback: profile);
      return _localStore.saveProfile(
        savedProfile.copyWith(
          avatarLocalPath: profile.avatarLocalPath,
          avatarUrl: savedProfile.avatarUrl.isEmpty
              ? profile.avatarUrl
              : savedProfile.avatarUrl,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        rethrow;
      }
      if (!_shouldFallbackToLocal(error)) {
        rethrow;
      }

      return _localStore.saveProfile(profile);
    }
  }

  @override
  Future<ProfileRecord> uploadAvatar({
    required ProfileRecord profile,
    required String imagePath,
  }) async {
    if (!await _hasAccessToken()) {
      return _localStore.uploadAvatar(profile: profile, imagePath: imagePath);
    }

    try {
      final body = await _apiClient.postMultipart(
        ApiEndpoints.user.avatar,
        fieldName: 'avatar',
        filePath: imagePath,
      );

      final responseMap = asMap(
        unwrapBody(body, keys: const ['data', 'profile']),
      );
      final avatarUrl = readString(
        responseMap,
        const ['avatarUrl', 'avatar_url', 'url', 'path'],
        fallback: profile.avatarUrl,
      );

      return _localStore.saveProfile(
        profile.copyWith(
          avatarLocalPath: imagePath,
          avatarUrl: avatarUrl,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        rethrow;
      }
      if (!_shouldFallbackToLocal(error)) {
        rethrow;
      }

      return _localStore.uploadAvatar(profile: profile, imagePath: imagePath);
    }
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
  }

  Future<dynamic> _submitProfileUpdate(Map<String, dynamic> payload) async {
    try {
      return await _apiClient.putJson(
        ApiEndpoints.user.me,
        body: payload,
      );
    } on ApiException catch (error) {
      if (!_shouldRetryProfileUpdateWithPost(error)) {
        rethrow;
      }
    }

    return _apiClient.postJson(
      ApiEndpoints.user.me,
      body: <String, dynamic>{
        ...payload,
        '_method': 'PUT',
      },
    );
  }

  bool _shouldFallbackToLocal(ApiException error) => error.statusCode == null;

  bool _shouldRetryProfileUpdateWithPost(ApiException error) {
    return error.statusCode == 404 || error.statusCode == 405;
  }

  ProfileRecord _parseProfile(dynamic body, {required ProfileRecord fallback}) {
    final root = asMap(body);
    final payload = root.containsKey('email') || root.containsKey('name')
        ? root
        : asMap(unwrapBody(body, keys: const ['data', 'user', 'profile']));

    return ProfileRecord(
      id: readString(payload, const ['id', 'user_id'], fallback: fallback.id),
      name: readString(payload, const ['name'], fallback: fallback.name),
      email: readString(payload, const ['email'], fallback: fallback.email),
      phone: readString(
        payload,
        const ['phone', 'phone_number'],
        fallback: fallback.phone,
      ),
      bio: readString(payload, const ['bio'], fallback: fallback.bio),
      avatarLocalPath: fallback.avatarLocalPath,
      avatarUrl: readString(
        payload,
        const ['avatarUrl', 'avatar_url', 'avatar', 'photo'],
        fallback: fallback.avatarUrl,
      ),
    );
  }
}
