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
  String _lastErrorMessage = '';

  String get name => _profile.name;
  String get email => _profile.email;
  String get phone => _profile.phone;
  String get bio => _profile.bio;
  String? get imagePath => _profile.avatarLocalPath;
  String get avatarUrl => _profile.avatarUrl;
  bool get hasProfileImage =>
      (imagePath != null && File(imagePath!).existsSync()) ||
      avatarUrl.trim().isNotEmpty;
  bool get isLoaded => _isLoaded;
  String get lastErrorMessage => _lastErrorMessage;

  String get firstName {
    final parts = _splitName(_profile.name);
    return parts.isEmpty ? 'Learner' : parts.first;
  }

  String get initials {
    final parts = _splitName(_profile.name);
    if (parts.isEmpty) {
      return 'Photo';
    }

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    final nextProfile = _profile.copyWith(
      name: _normalizedValue(name, ProfileRecord.defaultName),
      email: _normalizedValue(email, ProfileRecord.defaultEmail),
      phone: _normalizedValue(phone, ProfileRecord.defaultPhone),
      bio: _normalizedValue(bio, ProfileRecord.defaultBio),
    );

    try {
      _lastErrorMessage = '';
      _profile = await _repository.saveProfile(nextProfile);
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      update();
      return false;
    }
  }

  Future<void> updateEmail(String email) async {
    _profile = _profile.copyWith(
      email: _normalizedValue(email, ProfileRecord.defaultEmail),
    );
    update();
  }

  Future<bool> pickProfileImage(ImageSource source) async {
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
      final destinationPath =
          '${documentsDirectory.path}/profile_photo$extension';
      final destinationFile = File(destinationPath);

      if (destinationFile.existsSync()) {
        await destinationFile.delete();
      }

      await sourceFile.copy(destinationPath);
      _lastErrorMessage = '';
      _profile = await _repository.uploadAvatar(
        profile: _profile.copyWith(avatarLocalPath: destinationPath),
        imagePath: destinationPath,
      );
      update();
      return true;
    } catch (error) {
      _lastErrorMessage = error.toString();
      debugPrint('Failed to pick profile image: $error');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    _profile = await _repository.loadProfile();
    _isLoaded = true;
    update();
  }

  String _normalizedValue(String value, String fallback) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? fallback : trimmedValue;
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
}
