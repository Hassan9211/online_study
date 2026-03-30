import 'package:get/get.dart';

import '../../../features/home/controllers/message_center_controller.dart';
import '../../../features/home/controllers/profile_controller.dart';
import '../../../features/home/controllers/settings_controller.dart';
import '../models/auth_session_record.dart';
import '../repositories/auth_session_repository.dart';

class AuthSessionController extends GetxController {
  AuthSessionController(this._repository);

  final AuthSessionRepository _repository;

  bool _isReady = false;
  bool _isBusy = false;
  AuthSessionRecord _session = const AuthSessionRecord.empty();
  String _pendingEmail = '';
  String _pendingPassword = '';
  String _pendingPhone = '';
  bool _pendingTermsAccepted = false;
  String _lastErrorMessage = '';

  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  bool get isLoggedIn => _session.isLoggedIn;
  String get email => _session.email;
  String get password => _session.password;
  bool get hasSavedCredentials => _session.hasSavedCredentials;
  String get lastErrorMessage => _lastErrorMessage;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  void prepareRegistration({
    required String email,
    required String password,
    required bool termsAccepted,
  }) {
    _pendingEmail = email.trim();
    _pendingPassword = password.trim();
    _pendingTermsAccepted = termsAccepted;
  }

  Future<bool> logIn({required String email, required String password}) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return false;
    }

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      _session = await _repository.logIn(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      await _syncProfileEmail(_session.email);
      await _refreshAppData();
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> sendOtp({required String phone}) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return false;
    }

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.sendOtp(phone: normalizedPhone);
      _pendingPhone = normalizedPhone;
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> completeRegistration({
    required String phone,
    required String code,
  }) async {
    final normalizedPhone = phone.trim().isEmpty ? _pendingPhone : phone.trim();
    final normalizedCode = code.trim();
    if (_pendingEmail.isEmpty ||
        _pendingPassword.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedCode.isEmpty) {
      return false;
    }

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.verifyOtp(phone: normalizedPhone, code: normalizedCode);
      _session = await _repository.signUp(
        email: _pendingEmail,
        password: _pendingPassword,
        phone: normalizedPhone,
        termsAccepted: _pendingTermsAccepted,
      );
      _pendingEmail = '';
      _pendingPassword = '';
      _pendingPhone = '';
      _pendingTermsAccepted = false;

      await _syncProfileEmail(_session.email);
      await _refreshAppData();
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return;
    }

    _session = _session.copyWith(email: normalizedEmail);
    await _persistSession();
    update();
  }

  bool isCurrentPasswordValid(String currentPassword) {
    return currentPassword.trim() == _session.password;
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setBusy(true);
    _lastErrorMessage = '';

    try {
      _session = await _repository.changePassword(
        session: _session,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.requestPasswordReset(email: normalizedEmail);
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.resetPassword(
        email: email.trim(),
        token: token.trim(),
        newPassword: newPassword.trim(),
      );
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logOut(session: _session);
    } catch (_) {
      // Local logout should still happen even if the API call fails.
    }

    _session = _session.copyWith(
      isLoggedIn: false,
      accessToken: '',
      refreshToken: '',
    );
    _pendingEmail = '';
    _pendingPassword = '';
    _pendingPhone = '';
    _pendingTermsAccepted = false;
    await _persistSession();
    update();
  }

  Future<void> _loadSession() async {
    _session = await _repository.loadSession();
    _isReady = true;

    update();
  }

  Future<void> _persistSession() async {
    await _repository.saveSession(_session);
  }

  Future<void> _syncProfileEmail(String email) async {
    if (!Get.isRegistered<ProfileController>()) {
      return;
    }

    await Get.find<ProfileController>().updateEmail(email);
  }

  Future<void> _refreshAppData() async {
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().refreshProfile();
    }
    if (Get.isRegistered<MessageCenterController>()) {
      await Get.find<MessageCenterController>().refreshState();
    }
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().refreshSettings();
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    update();
  }
}
