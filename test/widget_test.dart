import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:online_study/core/network/api_client.dart';
import 'package:online_study/features/auth/controllers/auth_session_controller.dart';
import 'package:online_study/features/auth/models/auth_session_record.dart';
import 'package:online_study/features/auth/repositories/auth_session_repository.dart';
import 'package:online_study/features/auth/screens/log_in_screen.dart';
import 'package:online_study/features/auth/screens/phone_verification_screen.dart';
import 'package:online_study/features/auth/screens/sign_up_screen.dart';
import 'package:online_study/features/onboarding/controllers/onboarding_controller.dart';
import 'package:online_study/features/onboarding/repositories/local_onboarding_content_repository.dart';
import 'package:online_study/features/onboarding/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Onboarding screen renders the first slide', (tester) async {
    Get.put<OnboardingController>(
      OnboardingController(LocalOnboardingContentRepository()),
    );

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
    await tester.pump();

    expect(find.text('Numerous free\ntrial courses'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Sign up'), findsNothing);
  });

  testWidgets('Sign up screen renders the form', (tester) async {
    Get.put<AuthSessionController>(
      AuthSessionController(_FakeAuthSessionRepository()),
    );

    await tester.pumpWidget(const GetMaterialApp(home: SignUpScreen()));

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Your Email'), findsOneWidget);
    expect(_textFieldWithHint('Email'), findsOneWidget);
    expect(_textFieldWithHint('Password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('Sign up continues into phone OTP flow', (tester) async {
    Get.put<AuthSessionController>(
      AuthSessionController(_FakeAuthSessionRepository()),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/sign-up',
        getPages: [
          GetPage(name: '/sign-up', page: () => const SignUpScreen()),
          GetPage(
            name: '/auth/verify-otp',
            page: () => const PhoneVerificationScreen(),
          ),
        ],
      ),
    );

    await tester.enterText(_textFieldWithHint('Email'), 'learner@example.com');
    await tester.enterText(_textFieldWithHint('Password'), 'secret123');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Phone'), findsOneWidget);
    expect(_textFieldWithHint('Phone number'), findsOneWidget);
  });

  test('ApiException includes the HTTP status code in its text', () {
    const error = ApiException('Validation failed.', statusCode: 422);

    expect(error.toString(), 'Validation failed. (HTTP 422)');
  });

  testWidgets('Log in screen renders the form', (tester) async {
    Get.put<AuthSessionController>(
      AuthSessionController(_FakeAuthSessionRepository()),
    );

    await tester.pumpWidget(const GetMaterialApp(home: LogInScreen()));

    expect(find.text('Log In'), findsWidgets);
    expect(find.text('Your Email'), findsOneWidget);
    expect(_textFieldWithHint('Email'), findsOneWidget);
    expect(_textFieldWithHint('Password'), findsOneWidget);
    expect(find.text('Forget password?'), findsOneWidget);
    expect(find.text('Or login with'), findsOneWidget);
  });
}

Finder _textFieldWithHint(String hintText) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hintText,
    description: 'TextField with hint "$hintText"',
  );
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthSessionRecord _session = const AuthSessionRecord.empty();

  @override
  Future<AuthSessionRecord> changePassword({
    required AuthSessionRecord session,
    required String currentPassword,
    required String newPassword,
  }) async {
    _session = session.copyWith(password: newPassword);
    return _session;
  }

  @override
  Future<AuthSessionRecord> loadSession() async => _session;

  @override
  Future<AuthSessionRecord> logIn({
    required String email,
    required String password,
  }) async {
    _session = AuthSessionRecord(
      isLoggedIn: true,
      email: email,
      password: password,
      userId: 'test-user',
      accessToken: 'test-token',
      refreshToken: 'test-refresh-token',
    );
    return _session;
  }

  @override
  Future<void> logOut({required AuthSessionRecord session}) async {
    _session = const AuthSessionRecord.empty();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _session = _session.copyWith(password: newPassword);
  }

  @override
  Future<void> saveSession(AuthSessionRecord session) async {
    _session = session;
  }

  @override
  Future<void> sendOtp({String email = '', String phone = ''}) async {}

  @override
  Future<AuthSessionRecord> signUp({
    required String email,
    required String password,
    required String phone,
    required bool termsAccepted,
  }) async {
    _session = AuthSessionRecord(
      isLoggedIn: true,
      email: email,
      password: password,
      userId: 'test-user',
      accessToken: 'test-token',
      refreshToken: 'test-refresh-token',
    );
    return _session;
  }

  @override
  Future<AuthSessionRecord?> verifyOtp({
    String email = '',
    String phone = '',
    required String code,
    String fallbackEmail = '',
    String fallbackPassword = '',
  }) async {
    return null;
  }
}
