import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_record.dart';
import 'profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  static const String _idKey = 'profile_id';
  static const String _nameKey = 'profile_name';
  static const String _emailKey = 'profile_email';
  static const String _phoneKey = 'profile_phone';
  static const String _bioKey = 'profile_bio';
  static const String _imagePathKey = 'profile_image_path';
  static const String _avatarUrlKey = 'profile_avatar_url';

  @override
  Future<ProfileRecord> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final savedImagePath = preferences.getString(_imagePathKey);
    final hasSavedImage =
        savedImagePath != null && File(savedImagePath).existsSync();

    if (savedImagePath != null && !hasSavedImage) {
      await preferences.remove(_imagePathKey);
    }

    return ProfileRecord(
      id: preferences.getString(_idKey) ?? ProfileRecord.defaultId,
      name: preferences.getString(_nameKey) ?? ProfileRecord.defaultName,
      email: preferences.getString(_emailKey) ?? ProfileRecord.defaultEmail,
      phone: preferences.getString(_phoneKey) ?? ProfileRecord.defaultPhone,
      bio: preferences.getString(_bioKey) ?? ProfileRecord.defaultBio,
      avatarLocalPath: hasSavedImage ? savedImagePath : null,
      avatarUrl: preferences.getString(_avatarUrlKey) ?? '',
    );
  }

  @override
  Future<ProfileRecord> saveProfile(ProfileRecord profile) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_idKey, profile.id);
    await preferences.setString(_nameKey, profile.name);
    await preferences.setString(_emailKey, profile.email);
    await preferences.setString(_phoneKey, profile.phone);
    await preferences.setString(_bioKey, profile.bio);
    await preferences.setString(_avatarUrlKey, profile.avatarUrl);

    if (profile.avatarLocalPath == null) {
      await preferences.remove(_imagePathKey);
    } else {
      await preferences.setString(_imagePathKey, profile.avatarLocalPath!);
    }

    return profile;
  }

  @override
  Future<ProfileRecord> uploadAvatar({
    required ProfileRecord profile,
    required String imagePath,
  }) {
    return saveProfile(profile.copyWith(avatarLocalPath: imagePath));
  }
}
