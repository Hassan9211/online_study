import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/app_settings_record.dart';
import 'local_settings_repository.dart';
import 'settings_repository.dart';

class RemoteSettingsRepository implements SettingsRepository {
  RemoteSettingsRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalSettingsRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  @override
  Future<AppSettingsRecord> loadCachedSettings() {
    return _localStore.loadSettings();
  }

  @override
  Future<AppSettingsRecord> loadSettings() async {
    final cachedSettings = await _localStore.loadSettings();
    if (!await _hasAccessToken()) {
      return cachedSettings;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.settings);
      final parsedSettings = _parseSettings(body, fallback: cachedSettings);
      return _localStore.saveSettings(parsedSettings);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return cachedSettings;
    } catch (_) {
      return cachedSettings;
    }
  }

  @override
  Future<AppSettingsRecord> saveSettings(AppSettingsRecord settings) async {
    if (!await _hasAccessToken()) {
      return _localStore.saveSettings(settings);
    }

    try {
      final body = await _submitSettingsUpdate(settings.toMap());
      final parsedSettings = _parseSettings(body, fallback: settings);
      return _localStore.saveSettings(parsedSettings);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
        rethrow;
      }
      return _localStore.saveSettings(settings);
    } catch (_) {
      return _localStore.saveSettings(settings);
    }
  }

  @override
  Future<void> clearCachedSettings() {
    return _localStore.clearCachedSettings();
  }

  Future<dynamic> _submitSettingsUpdate(Map<String, dynamic> payload) async {
    try {
      return await _apiClient.putJson(
        ApiEndpoints.user.settings,
        body: payload,
      );
    } on ApiException catch (error) {
      if (!_shouldRetrySettingsUpdateWithPost(error)) {
        rethrow;
      }
    }

    return _apiClient.postJson(
      ApiEndpoints.user.settings,
      body: <String, dynamic>{
        ...payload,
        '_method': 'PUT',
      },
    );
  }

  bool _shouldRetrySettingsUpdateWithPost(ApiException error) {
    return error.statusCode == 404 || error.statusCode == 405;
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
  }

  AppSettingsRecord _parseSettings(
    dynamic body, {
    required AppSettingsRecord fallback,
  }) {
    final root = asMap(body);
    final payload = asMap(
      unwrapBody(body, keys: const ['data', 'settings', 'preferences']),
    );
    final data = readMap(payload, const ['data']);
    final source = data.isEmpty ? payload : data;

    return AppSettingsRecord(
      pushNotifications: readBool(
        source,
        const ['push_notifications', 'pushNotifications'],
        fallback: fallback.pushNotifications,
      ),
      courseReminders: readBool(
        source,
        const ['course_reminders', 'courseReminders'],
        fallback: fallback.courseReminders,
      ),
      wifiDownloadsOnly: readBool(
        source,
        const ['wifi_downloads_only', 'wifiDownloadsOnly'],
        fallback: fallback.wifiDownloadsOnly,
      ),
      privateProfile: readBool(
        source,
        const ['private_profile', 'privateProfile'],
        fallback: readBool(
          root,
          const ['private_profile', 'privateProfile'],
          fallback: fallback.privateProfile,
        ),
      ),
    );
  }
}
