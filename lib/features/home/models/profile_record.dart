class ProfileRecord {
  const ProfileRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    this.avatarLocalPath,
    this.avatarUrl = '',
  });

  static const String defaultId = 'local-user';
  static const String defaultName = 'Kristin Watson';
  static const String defaultEmail = 'kristin.watson@email.com';
  static const String defaultPhone = '+92 300 1234567';
  static const String defaultBio =
      'Product designer who loves learning, prototyping, and clean UI.';

  const ProfileRecord.defaults()
      : id = defaultId,
        name = defaultName,
        email = defaultEmail,
        phone = defaultPhone,
        bio = defaultBio,
        avatarLocalPath = null,
        avatarUrl = '';

  final String id;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String? avatarLocalPath;
  final String avatarUrl;

  ProfileRecord copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? avatarLocalPath,
    bool clearAvatarLocalPath = false,
    String? avatarUrl,
  }) {
    return ProfileRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarLocalPath: clearAvatarLocalPath
          ? null
          : avatarLocalPath ?? this.avatarLocalPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
