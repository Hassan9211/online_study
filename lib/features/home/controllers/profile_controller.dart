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

  String get name => _profile.name;
  String get email => _profile.email;
  String get phone => _profile.phone;
  String get bio => _profile.bio;
  String? get imagePath => _profile.avatarLocalPath;
  bool get hasProfileImage =>
      imagePath != null && File(imagePath!).existsSync();
  bool get isLoaded => _isLoaded;

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

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    _profile = _profile.copyWith(
      name: _normalizedValue(name, ProfileRecord.defaultName),
      email: _normalizedValue(email, ProfileRecord.defaultEmail),
      phone: _normalizedValue(phone, ProfileRecord.defaultPhone),
      bio: _normalizedValue(bio, ProfileRecord.defaultBio),
    );

    await _persistProfile();
    update();
  }

  Future<void> updateEmail(String email) async {
    _profile = _profile.copyWith(
      email: _normalizedValue(email, ProfileRecord.defaultEmail),
    );
    await _persistProfile();
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
      _profile = _profile.copyWith(avatarLocalPath: destinationPath);

      await _persistProfile();
      update();
      return true;
    } catch (error) {
      debugPrint('Failed to pick profile image: $error');
      return false;
    }
  }

  Future<void> _loadProfile() async {
    _profile = await _repository.loadProfile();
    _isLoaded = true;
    update();
  }

  Future<void> _persistProfile() async {
    await _repository.saveProfile(_profile);
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
