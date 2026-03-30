import '../models/app_settings_record.dart';

abstract interface class SettingsRepository {
  Future<AppSettingsRecord> loadSettings();
  Future<AppSettingsRecord> saveSettings(AppSettingsRecord settings);
}
