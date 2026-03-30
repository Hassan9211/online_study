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
  Future<AppSettingsRecord> loadSettings() async {
    final cachedSettings = await _localStore.loadSettings();
    if (!await _hasAccessToken()) {
      return cachedSettings;
    }

    try {
      final body = await _apiClient.getJson(ApiEndpoints.user.settings);
      final parsedSettings = _parseSettings(body, fallback: cachedSettings);
      return _localStore.saveSettings(parsedSettings);
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
      final payload = <String, dynamic>{
        ...settings.toMap(),
        'data': settings.toMap(),
      };
      final body = await _submitSettingsUpdate(payload);

      final parsedSettings = _parseSettings(body, fallback: settings);
      return _localStore.saveSettings(parsedSettings);
    } catch (_) {
      return _localStore.saveSettings(settings);
    }
  }

  Future<dynamic> _submitSettingsUpdate(Map<String, dynamic> payload) async {
    try {
      return await _apiClient.putJson(
        ApiEndpoints.user.settings,
        body: payload,
      );
    } on ApiException catch (error) {
      if (error.statusCode != null) {
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

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
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
