import '../models/profile_record.dart';

abstract interface class ProfileRepository {
  Future<ProfileRecord> loadProfile();
  Future<void> saveProfile(ProfileRecord profile);
}
