import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_routes.dart';
import '../core/controllers/network_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/no_internet_screen.dart';
import '../features/auth/controllers/auth_session_controller.dart';
import '../features/auth/repositories/auth_session_repository.dart';
import '../features/auth/repositories/local_auth_session_repository.dart';
import '../features/auth/screens/log_in_screen.dart';
import '../features/auth/screens/phone_verification_screen.dart';
import '../features/auth/screens/session_gate_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/home/controllers/message_center_controller.dart';
import '../features/home/controllers/profile_controller.dart';
import '../features/home/controllers/product_design_course_controller.dart';
import '../features/home/repositories/local_message_center_repository.dart';
import '../features/home/repositories/local_product_design_purchase_repository.dart';
import '../features/home/repositories/local_profile_repository.dart';
import '../features/home/repositories/local_support_repository.dart';
import '../features/home/repositories/message_center_repository.dart';
import '../features/home/repositories/product_design_purchase_repository.dart';
import '../features/home/repositories/profile_repository.dart';
import '../features/home/repositories/support_repository.dart';
import '../features/home/screens/account_menu_screens.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/my_courses_screen.dart';
import '../features/home/screens/product_design_course_screen.dart';
import '../features/home/screens/product_design_payment_screen.dart';
import '../features/home/screens/product_design_player_screen.dart';
import '../features/home/screens/support_content_screens.dart';
import '../features/onboarding/controllers/onboarding_controller.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

class OnlineStudyApp extends StatelessWidget {
  const OnlineStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Study',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.launch,
      initialBinding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthSessionRepository>()) {
          Get.put<AuthSessionRepository>(
            LocalAuthSessionRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<ProfileRepository>()) {
          Get.put<ProfileRepository>(LocalProfileRepository(), permanent: true);
        }
        if (!Get.isRegistered<MessageCenterRepository>()) {
          Get.put<MessageCenterRepository>(
            LocalMessageCenterRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<ProductDesignPurchaseRepository>()) {
          Get.put<ProductDesignPurchaseRepository>(
            LocalProductDesignPurchaseRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<SupportRepository>()) {
          Get.put<SupportRepository>(LocalSupportRepository(), permanent: true);
        }
        if (!Get.isRegistered<AuthSessionController>()) {
          Get.put<AuthSessionController>(
            AuthSessionController(Get.find<AuthSessionRepository>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<NetworkController>()) {
          Get.put<NetworkController>(NetworkController(), permanent: true);
        }
        if (!Get.isRegistered<ProfileController>()) {
          Get.put<ProfileController>(
            ProfileController(Get.find<ProfileRepository>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<MessageCenterController>()) {
          Get.put<MessageCenterController>(
            MessageCenterController(Get.find<MessageCenterRepository>()),
            permanent: true,
          );
        }
      }),
      builder: (context, child) {
        return GetBuilder<NetworkController>(
          builder: (networkController) {
            if (!networkController.hasConnection) {
              return NoInternetScreen(
                onRetry: networkController.recheckConnection,
                isChecking: networkController.isChecking,
              );
            }

            return child ?? const SizedBox.shrink();
          },
        );
      },
      getPages: [
        GetPage(name: AppRoutes.launch, page: () => const SessionGateScreen()),
        GetPage(
          name: AppRoutes.onboarding,
          page: () => const OnboardingScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<OnboardingController>(OnboardingController.new);
          }),
        ),
        GetPage(name: AppRoutes.signUp, page: () => const SignUpScreen()),
        GetPage(name: AppRoutes.logIn, page: () => const LogInScreen()),
        GetPage(
          name: AppRoutes.phoneVerification,
          page: () => const PhoneVerificationScreen(),
        ),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(
          name: AppRoutes.myCourses,
          page: () => const MyCoursesScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ProductDesignCourseController>()) {
              Get.lazyPut<ProductDesignCourseController>(
                () => ProductDesignCourseController(
                  Get.find<ProductDesignPurchaseRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.favouriteVideos,
          page: () => const FavouriteVideosScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ProductDesignCourseController>()) {
              Get.lazyPut<ProductDesignCourseController>(
                () => ProductDesignCourseController(
                  Get.find<ProductDesignPurchaseRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.editAccount,
          page: () => const EditAccountScreen(),
        ),
        GetPage(
          name: AppRoutes.settingsPrivacy,
          page: () => const SettingsPrivacyScreen(),
        ),
        GetPage(
          name: AppRoutes.changePassword,
          page: () => const ChangePasswordScreen(),
        ),
        GetPage(
          name: AppRoutes.helpCenter,
          page: () => const HelpCenterScreen(),
        ),
        GetPage(
          name: AppRoutes.privacyPolicy,
          page: () => const PrivacyPolicyScreen(),
        ),
        GetPage(
          name: AppRoutes.termsConditions,
          page: () => const TermsConditionsScreen(),
        ),
        GetPage(
          name: AppRoutes.supportRequest,
          page: () => const SupportRequestScreen(),
        ),
        GetPage(
          name: AppRoutes.productDesignCourse,
          page: () => const ProductDesignCourseScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ProductDesignCourseController>()) {
              Get.lazyPut<ProductDesignCourseController>(
                () => ProductDesignCourseController(
                  Get.find<ProductDesignPurchaseRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.productDesignPlayer,
          page: () => const ProductDesignPlayerScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ProductDesignCourseController>()) {
              Get.lazyPut<ProductDesignCourseController>(
                () => ProductDesignCourseController(
                  Get.find<ProductDesignPurchaseRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.productDesignPayment,
          page: () => const ProductDesignPaymentScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ProductDesignCourseController>()) {
              Get.lazyPut<ProductDesignCourseController>(
                () => ProductDesignCourseController(
                  Get.find<ProductDesignPurchaseRepository>(),
                ),
              );
            }
          }),
        ),
      ],
    );
  }
}
