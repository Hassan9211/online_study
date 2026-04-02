import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../features/home/controllers/message_center_controller.dart';
import '../../../features/home/controllers/profile_controller.dart';
import '../../../features/home/controllers/product_design_course_controller.dart';
import '../../../features/home/controllers/settings_controller.dart';
import '../../../features/home/controllers/course_catalog_controller.dart';
import '../../../features/home/controllers/course_purchase_controller.dart';
import '../../../features/home/controllers/home_dashboard_controller.dart';
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
  String get pendingEmail => _pendingEmail;
  String get pendingPhone => _pendingPhone;
  bool get hasSavedCredentials => _session.hasSavedCredentials;
  String get lastErrorMessage => _lastErrorMessage;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  // Signup starts before OTP verification, so we cache the entered fields here
  // and reuse them if the verify step needs to fall back to a full signup call.
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
      await _prepareProfileForSession(email: _session.email, userId: _session.userId);
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

  Future<bool> sendOtp({String email = '', String phone = ''}) async {
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    if (normalizedEmail.isEmpty && normalizedPhone.isEmpty) {
      return false;
    }

    // This step only asks the backend to issue an OTP. The user session is not
    // created until verify-otp succeeds, or signup is used as a fallback.
    _logOtpDebug(
      'OTP send requested for email=$normalizedEmail phone=$normalizedPhone',
    );

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.sendOtp(
        email: normalizedEmail,
        phone: normalizedPhone,
      );
      if (normalizedEmail.isNotEmpty) {
        _pendingEmail = normalizedEmail;
      }
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
    String email = '',
    String phone = '',
    required String code,
  }) async {
    final normalizedEmail = email.trim().isNotEmpty
        ? email.trim()
        : _pendingEmail.trim();
    final normalizedPhone = _pendingPhone.trim().isNotEmpty
        ? _pendingPhone.trim()
        : phone.trim();
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '').trim();
    _logOtpDebug(
      'OTP verify requested with email=$normalizedEmail pendingPhone=$_pendingPhone enteredPhone=${phone.trim()} requestPhone=$normalizedPhone code=$normalizedCode',
    );
    if ((normalizedEmail.isEmpty && normalizedPhone.isEmpty) ||
        normalizedCode.isEmpty) {
      return false;
    }

    _setBusy(true);
    _lastErrorMessage = '';

    try {
      // Some backends create the user and return a ready session on verify-otp.
      // If they only confirm the code, we fall back to signup using the cached
      // registration fields from prepareRegistration().
      final verifiedSession = await _repository.verifyOtp(
        email: normalizedEmail,
        phone: normalizedPhone,
        code: normalizedCode,
        fallbackEmail: normalizedEmail,
        fallbackPassword: _pendingPassword,
      );

      if (verifiedSession != null) {
        _session = verifiedSession.copyWith(
          email: verifiedSession.email.trim().isEmpty
              ? normalizedEmail
              : verifiedSession.email,
          password: _pendingPassword.trim().isEmpty
              ? verifiedSession.password
              : _pendingPassword.trim(),
        );
        await _persistSession();
      } else {
        if (_pendingEmail.isEmpty || _pendingPassword.isEmpty) {
          return false;
        }

        _session = await _repository.signUp(
          email: _pendingEmail,
          password: _pendingPassword,
          phone: normalizedPhone,
          termsAccepted: _pendingTermsAccepted,
        );
      }

      final profileEmail = _session.email.trim().isEmpty
          ? normalizedEmail
          : _session.email;
      _pendingEmail = '';
      _pendingPassword = '';
      _pendingPhone = '';
      _pendingTermsAccepted = false;

      await _prepareProfileForSession(
        email: profileEmail,
        phone: normalizedPhone,
        userId: _session.userId,
      );
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
    required String code,
    required String newPassword,
  }) async {
    _setBusy(true);
    _lastErrorMessage = '';

    try {
      await _repository.resetPassword(
        email: email.trim(),
        code: code.trim(),
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
    if (Get.isRegistered<MessageCenterController>()) {
      await Get.find<MessageCenterController>().resetForSignedOutUser();
    }
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().clearProfile();
    }
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().resetForSignedOutUser();
    }
    if (Get.isRegistered<CourseCatalogController>()) {
      await Get.find<CourseCatalogController>().resetForSignedOutUser();
    }
    if (Get.isRegistered<CoursePurchaseController>()) {
      await Get.find<CoursePurchaseController>().resetForSignedOutUser();
    }
    if (Get.isRegistered<ProductDesignCourseController>()) {
      await Get.find<ProductDesignCourseController>().resetForSignedOutUser();
    }
    if (Get.isRegistered<HomeDashboardController>()) {
      await Get.find<HomeDashboardController>().resetForSignedOutUser();
    }
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

  Future<void> _prepareProfileForSession({
    required String email,
    String phone = '',
    String userId = '',
  }) async {
    if (!Get.isRegistered<ProfileController>()) {
      return;
    }

    await Get.find<ProfileController>().seedProfileForSession(
      email: email,
      phone: phone,
      userId: userId,
    );
  }

  Future<void> _refreshAppData() async {
    // Auth state affects several tabs at once, so we refresh the shared
    // controllers here after login/signup instead of waiting for manual reloads.
    final refreshTasks = <Future<void>>[];

    if (Get.isRegistered<ProfileController>()) {
      refreshTasks.add(Get.find<ProfileController>().refreshProfile());
    }
    if (Get.isRegistered<MessageCenterController>()) {
      refreshTasks.add(Get.find<MessageCenterController>().refreshState());
    }
    if (Get.isRegistered<SettingsController>()) {
      refreshTasks.add(Get.find<SettingsController>().refreshSettings());
    }
    if (Get.isRegistered<CourseCatalogController>()) {
      refreshTasks.add(Get.find<CourseCatalogController>().refreshAll());
    }
    if (Get.isRegistered<HomeDashboardController>()) {
      refreshTasks.add(Get.find<HomeDashboardController>().refreshAll());
    }

    if (refreshTasks.isNotEmpty) {
      await Future.wait<void>(refreshTasks);
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    update();
  }

  void _logOtpDebug(String message) {
    if (kDebugMode) {
      debugPrint('OTP flow -> $message');
    }
  }
}
