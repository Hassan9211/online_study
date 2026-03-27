import 'package:get/get.dart';

import '../../../features/home/controllers/profile_controller.dart';
import '../models/auth_session_record.dart';
import '../repositories/auth_session_repository.dart';

class AuthSessionController extends GetxController {
  AuthSessionController(this._repository);

  final AuthSessionRepository _repository;

  bool _isReady = false;
  AuthSessionRecord _session = const AuthSessionRecord.empty();
  String _pendingEmail = '';
  String _pendingPassword = '';

  bool get isReady => _isReady;
  bool get isLoggedIn => _session.isLoggedIn;
  String get email => _session.email;
  String get password => _session.password;
  bool get hasSavedCredentials => _session.hasSavedCredentials;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  void prepareRegistration({required String email, required String password}) {
    _pendingEmail = email.trim();
    _pendingPassword = password.trim();
  }

  Future<bool> logIn({required String email, required String password}) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return false;
    }

    if (hasSavedCredentials &&
        (normalizedEmail.toLowerCase() != _session.email.toLowerCase() ||
            normalizedPassword != _session.password)) {
      return false;
    }

    _session = _session.copyWith(
      email: normalizedEmail,
      password: normalizedPassword,
      isLoggedIn: true,
    );

    await _syncProfileEmail(normalizedEmail);
    await _persistSession();
    update();
    return true;
  }

  Future<void> completeRegistration() async {
    if (_pendingEmail.isEmpty || _pendingPassword.isEmpty) {
      return;
    }

    _session = _session.copyWith(
      email: _pendingEmail,
      password: _pendingPassword,
      isLoggedIn: true,
    );
    _pendingEmail = '';
    _pendingPassword = '';

    await _syncProfileEmail(_session.email);
    await _persistSession();
    update();
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

  Future<void> updatePassword(String newPassword) async {
    _session = _session.copyWith(password: newPassword.trim());
    await _persistSession();
    update();
  }

  Future<void> logout() async {
    _session = _session.copyWith(
      isLoggedIn: false,
      accessToken: '',
      refreshToken: '',
    );
    _pendingEmail = '';
    _pendingPassword = '';
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
}
