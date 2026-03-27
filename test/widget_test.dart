import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:online_study/app/app.dart';
import 'package:online_study/features/auth/screens/log_in_screen.dart';
import 'package:online_study/features/auth/screens/sign_up_screen.dart';

void main() {
  testWidgets('Onboarding screen renders the first slide', (tester) async {
    await tester.pumpWidget(const OnlineStudyApp());

    expect(find.text('Numerous free\ntrial courses'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Sign up'), findsNothing);
  });

  testWidgets('Sign up screen renders the form', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SignUpScreen()));

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Your Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Creat account'), findsOneWidget);
  });

  testWidgets('Log in screen renders the form', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LogInScreen()));

    expect(find.text('Log In'), findsWidgets);
    expect(find.text('Your Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forget password?'), findsOneWidget);
    expect(find.text('Or login with'), findsOneWidget);
  });
}
