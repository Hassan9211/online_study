import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_record.dart';
import 'settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  static const String _pushNotificationsKey = 'settings_push_notifications';
  static const String _courseRemindersKey = 'settings_course_reminders';
  static const String _wifiDownloadsOnlyKey = 'settings_wifi_downloads_only';
  static const String _privateProfileKey = 'settings_private_profile';

  @override
  Future<AppSettingsRecord> loadCachedSettings() => loadSettings();

  @override
  Future<AppSettingsRecord> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettingsRecord(
      pushNotifications:
          preferences.getBool(_pushNotificationsKey) ??
          const AppSettingsRecord.defaults().pushNotifications,
      courseReminders:
          preferences.getBool(_courseRemindersKey) ??
          const AppSettingsRecord.defaults().courseReminders,
      wifiDownloadsOnly:
          preferences.getBool(_wifiDownloadsOnlyKey) ??
          const AppSettingsRecord.defaults().wifiDownloadsOnly,
      privateProfile:
          preferences.getBool(_privateProfileKey) ??
          const AppSettingsRecord.defaults().privateProfile,
    );
  }

  @override
  Future<AppSettingsRecord> saveSettings(AppSettingsRecord settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _pushNotificationsKey,
      settings.pushNotifications,
    );
    await preferences.setBool(_courseRemindersKey, settings.courseReminders);
    await preferences.setBool(
      _wifiDownloadsOnlyKey,
      settings.wifiDownloadsOnly,
    );
    await preferences.setBool(_privateProfileKey, settings.privateProfile);
    return settings;
  }

  @override
  Future<void> clearCachedSettings() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pushNotificationsKey);
    await preferences.remove(_courseRemindersKey);
    await preferences.remove(_wifiDownloadsOnlyKey);
    await preferences.remove(_privateProfileKey);
  }
}
