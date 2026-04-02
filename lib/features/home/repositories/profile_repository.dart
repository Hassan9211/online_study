import '../models/profile_record.dart';

abstract interface class ProfileRepository {
  Future<ProfileRecord> loadCachedProfile();
  Future<ProfileRecord> saveCachedProfile(ProfileRecord profile);
  Future<void> clearCachedProfile();
  Future<ProfileRecord> loadProfile();
  Future<ProfileRecord> saveProfile(ProfileRecord profile);
  Future<ProfileRecord> uploadAvatar({
    required ProfileRecord profile,
    required String imagePath,
  });
}
