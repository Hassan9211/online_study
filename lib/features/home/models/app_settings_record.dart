class AppSettingsRecord {
  const AppSettingsRecord({
    required this.pushNotifications,
    required this.courseReminders,
    required this.wifiDownloadsOnly,
    required this.privateProfile,
  });

  const AppSettingsRecord.defaults()
      : pushNotifications = true,
        courseReminders = true,
        wifiDownloadsOnly = true,
        privateProfile = false;

  final bool pushNotifications;
  final bool courseReminders;
  final bool wifiDownloadsOnly;
  final bool privateProfile;

  AppSettingsRecord copyWith({
    bool? pushNotifications,
    bool? courseReminders,
    bool? wifiDownloadsOnly,
    bool? privateProfile,
  }) {
    return AppSettingsRecord(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      courseReminders: courseReminders ?? this.courseReminders,
      wifiDownloadsOnly: wifiDownloadsOnly ?? this.wifiDownloadsOnly,
      privateProfile: privateProfile ?? this.privateProfile,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'push_notifications': pushNotifications,
      'course_reminders': courseReminders,
      'wifi_downloads_only': wifiDownloadsOnly,
      'private_profile': privateProfile,
    };
  }
}
