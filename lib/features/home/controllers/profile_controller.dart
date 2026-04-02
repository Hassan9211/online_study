import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/profile_record.dart';
import '../repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  final ImagePicker _imagePicker = ImagePicker();

  ProfileRecord _profile = const ProfileRecord.defaults();
  bool _isLoaded = false;
  bool _isSaving = false;
  String _lastErrorMessage = '';

  String get name => _profile.name;
  String get displayName => _displayNameFor(_profile);
  String get email => _profile.email;
  String get phone => _profile.phone;
  String get bio => _profile.bio;
  String? get imagePath => _profile.avatarLocalPath;
  String get avatarUrl => _profile.avatarUrl;
  bool get hasProfileImage =>
      (imagePath != null && File(imagePath!).existsSync()) ||
      avatarUrl.trim().isNotEmpty;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String get lastErrorMessage => _lastErrorMessage;

  String get firstName {
    final parts = _splitName(displayName);
    return parts.isEmpty ? 'Learner' : parts.first;
  }

  String get initials {
    final parts = _splitName(displayName);
    if (parts.isEmpty) {
      return 'Photo';
    }

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final cachedProfile = await _repository.loadCachedProfile();
    _profile = _sanitizeProfile(cachedProfile);
    _isLoaded = true;
    update();
    await _loadProfile();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    final previousProfile = _profile;
    final normalizedEmail = _normalizedValue(email, ProfileRecord.defaultEmail);
    final nextProfile = _profile.copyWith(
      name: _normalizedDisplayName(name, normalizedEmail),
      email: normalizedEmail,
      phone: _normalizedValue(phone, ProfileRecord.defaultPhone),
      bio: _normalizedValue(bio, ProfileRecord.defaultBio),
    );

    _isSaving = true;
    try {
      _lastErrorMessage = '';
      _profile = nextProfile;
      update();
      _profile = await _repository.saveProfile(nextProfile);
      update();
      return true;
    } catch (error) {
      _profile = previousProfile;
      _lastErrorMessage = error.toString();
      update();
      return false;
    } finally {
      _isSaving = false;
      update();
    }
  }

  Future<void> updateEmail(String email) async {
    final normalizedEmail = email.trim();
    _profile = _sanitizeProfile(
      _profile.copyWith(
        email: normalizedEmail,
        name: _profile.name.trim().isEmpty
            ? _deriveNameFromEmail(normalizedEmail)
            : _profile.name,
      ),
    );
    update();
  }

  Future<void> seedProfileForSession({
    required String email,
    String phone = '',
    String userId = '',
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedUserId = userId.trim();
    final derivedName = _deriveNameFromEmail(normalizedEmail);
    final sameUser =
        normalizedEmail.isNotEmpty &&
        _profile.email.trim().toLowerCase() == normalizedEmail.toLowerCase();

    final nextProfile = sameUser
        ? _profile.copyWith(
            id: normalizedUserId.isEmpty ? _profile.id : normalizedUserId,
            name: _profile.name.trim().isEmpty ? derivedName : _profile.name,
            email: normalizedEmail,
            phone: normalizedPhone.isEmpty ? _profile.phone : normalizedPhone,
          )
        : ProfileRecord(
            id: normalizedUserId,
            name: derivedName,
            email: normalizedEmail,
            phone: normalizedPhone,
            bio: '',
            avatarLocalPath: null,
            avatarUrl: '',
          );

    _profile = _sanitizeProfile(nextProfile);

    _isLoaded = true;
    await _repository.saveCachedProfile(_profile);
    update();
  }

  Future<void> clearProfile() async {
    _profile = const ProfileRecord.defaults();
    _isLoaded = true;
    _lastErrorMessage = '';
    await _repository.clearCachedProfile();
    update();
  }

  Future<bool> pickProfileImage(ImageSource source) async {
    final previousProfile = _profile;
    ProfileRecord? optimisticProfile;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1400,
      );

      if (pickedFile == null) {
        return false;
      }

      final sourceFile = File(pickedFile.path);
      if (!sourceFile.existsSync()) {
        return false;
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final extension = _fileExtension(pickedFile.name);
      final previousImagePath = _profile.avatarLocalPath;
      final destinationPath =
          '${documentsDirectory.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}$extension';

      await sourceFile.copy(destinationPath);
      optimisticProfile = _profile.copyWith(avatarLocalPath: destinationPath);
      _profile = optimisticProfile;
      update();
      await _repository.saveCachedProfile(optimisticProfile);
      _lastErrorMessage = '';
      _profile = await _repository.uploadAvatar(
        profile: optimisticProfile,
        imagePath: destinationPath,
      );
      if (previousImagePath != null && previousImagePath != destinationPath) {
        unawaited(_deleteLocalImage(previousImagePath));
      }
      update();
      return true;
    } catch (error) {
      _profile = optimisticProfile ?? previousProfile;
      update();
      _lastErrorMessage = error.toString();
      debugPrint('Failed to pick profile image: $error');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    _profile = _sanitizeProfile(await _repository.loadProfile());
    _isLoaded = true;
    update();
  }

  String _normalizedValue(String value, String fallback) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? fallback : trimmedValue;
  }

  String _normalizedDisplayName(String value, String email) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty) {
      return trimmedValue;
    }

    return _deriveNameFromEmail(email);
  }

  ProfileRecord _sanitizeProfile(ProfileRecord profile) {
    final displayName = profile.name.trim().isEmpty
        ? _deriveNameFromEmail(profile.email)
        : profile.name.trim();

    return profile.copyWith(
      name: displayName,
      phone: profile.phone.trim(),
      bio: profile.bio.trim(),
    );
  }

  String _displayNameFor(ProfileRecord profile) {
    final explicitName = profile.name.trim();
    if (explicitName.isNotEmpty) {
      return explicitName;
    }

    final derivedName = _deriveNameFromEmail(profile.email);
    return derivedName.isEmpty ? 'Learner' : derivedName;
  }

  String _deriveNameFromEmail(String email) {
    final localPart = email.trim().split('@').first.trim();
    if (localPart.isEmpty) {
      return '';
    }

    final words = localPart
        .split(RegExp(r'[._\-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final cleaned = part.trim();
          return cleaned[0].toUpperCase() + cleaned.substring(1);
        })
        .toList();

    return words.join(' ');
  }

  List<String> _splitName(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }

    return fileName.substring(dotIndex);
  }

  Future<void> _deleteLocalImage(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
