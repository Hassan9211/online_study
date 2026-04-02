import 'dart:async';

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
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final cachedSettings = await _repository.loadCachedSettings();
    _settings = cachedSettings;
    _isLoaded = true;
    update();
    await _loadSettings();
  }

  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  Future<void> resetForSignedOutUser() async {
    _settings = const AppSettingsRecord.defaults();
    _isLoaded = true;
    _isSaving = false;
    _lastErrorMessage = '';
    await _repository.clearCachedSettings();
    update();
  }

  Future<bool> updateSettings({
    bool? pushNotifications,
    bool? courseReminders,
    bool? wifiDownloadsOnly,
    bool? privateProfile,
  }) async {
    final previousSettings = _settings;
    final nextSettings = _settings.copyWith(
      pushNotifications: pushNotifications,
      courseReminders: courseReminders,
      wifiDownloadsOnly: wifiDownloadsOnly,
      privateProfile: privateProfile,
    );

    _settings = nextSettings;
    _isSaving = true;
    _lastErrorMessage = '';
    update();

    try {
      _settings = await _repository.saveSettings(nextSettings);
      update();
      return true;
    } catch (error) {
      _settings = previousSettings;
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
