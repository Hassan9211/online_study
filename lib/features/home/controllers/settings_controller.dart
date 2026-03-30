import 'package:get/get.dart';

import '../models/app_settings_record.dart';
import '../repositories/settings_repository.dart';

class SettingsController extends GetxController {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettingsRecord _settings = const AppSettingsRecord.defaults();
  bool _isLoaded = false;
  bool _isSaving = false;
  String _lastErrorMessage = '';

  bool get pushNotifications => _settings.pushNotifications;
  bool get courseReminders => _settings.courseReminders;
  bool get wifiDownloadsOnly => _settings.wifiDownloadsOnly;
  bool get privateProfile => _settings.privateProfile;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String get lastErrorMessage => _lastErrorMessage;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  Future<bool> updateSettings({
    bool? pushNotifications,
    bool? courseReminders,
    bool? wifiDownloadsOnly,
    bool? privateProfile,
  }) async {
    _isSaving = true;
    _lastErrorMessage = '';
    update();

    try {
      _settings = await _repository.saveSettings(
        _settings.copyWith(
          pushNotifications: pushNotifications,
          courseReminders: courseReminders,
          wifiDownloadsOnly: wifiDownloadsOnly,
          privateProfile: privateProfile,
        ),
      );
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _isSaving = false;
      update();
    }
  }

  Future<void> _loadSettings() async {
    _settings = await _repository.loadSettings();
    _isLoaded = true;
    update();
  }
}
