class AuthSessionRecord {
  const AuthSessionRecord({
    required this.isLoggedIn,
    required this.email,
    required this.password,
    this.userId = '',
    this.accessToken = '',
    this.refreshToken = '',
  });

  const AuthSessionRecord.empty()
      : isLoggedIn = false,
        email = '',
        password = '',
        userId = '',
        accessToken = '',
        refreshToken = '';

  final bool isLoggedIn;
  final String email;
  final String password;
  final String userId;
  final String accessToken;
  final String refreshToken;

  bool get hasSavedCredentials =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

  AuthSessionRecord copyWith({
    bool? isLoggedIn,
    String? email,
    String? password,
    String? userId,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthSessionRecord(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      password: password ?? this.password,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
