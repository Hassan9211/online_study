import '../models/app_settings_record.dart';

abstract interface class SettingsRepository {
  Future<AppSettingsRecord> loadCachedSettings();
  Future<AppSettingsRecord> loadSettings();
  Future<AppSettingsRecord> saveSettings(AppSettingsRecord settings);
  Future<void> clearCachedSettings();
}
