import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_routes.dart';
import '../core/network/api_client.dart';
import '../core/controllers/network_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/no_internet_screen.dart';
import '../features/auth/controllers/auth_session_controller.dart';
import '../features/auth/repositories/auth_session_repository.dart';
import '../features/auth/repositories/local_auth_session_repository.dart';
import '../features/auth/repositories/remote_auth_session_repository.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/log_in_screen.dart';
import '../features/auth/screens/phone_verification_screen.dart';
import '../features/auth/screens/session_gate_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/home/controllers/message_center_controller.dart';
import '../features/home/controllers/profile_controller.dart';
import '../features/home/controllers/product_design_course_controller.dart';
import '../features/home/controllers/settings_controller.dart';
import '../features/home/controllers/course_catalog_controller.dart';
import '../features/home/controllers/course_purchase_controller.dart';
import '../features/home/controllers/home_dashboard_controller.dart';
import '../features/home/repositories/course_catalog_repository.dart';
import '../features/home/repositories/course_purchase_repository.dart';
import '../features/home/repositories/local_course_catalog_repository.dart';
import '../features/home/repositories/local_course_purchase_repository.dart';
import '../features/home/repositories/local_home_dashboard_repository.dart';
import '../features/home/repositories/local_message_center_repository.dart';
import '../features/home/repositories/local_product_design_purchase_repository.dart';
import '../features/home/repositories/local_profile_repository.dart';
import '../features/home/repositories/local_settings_repository.dart';
import '../features/home/repositories/local_support_repository.dart';
import '../features/home/repositories/home_dashboard_repository.dart';
import '../features/home/repositories/message_center_repository.dart';
import '../features/home/repositories/product_design_purchase_repository.dart';
import '../features/home/repositories/profile_repository.dart';
import '../features/home/repositories/remote_course_catalog_repository.dart';
import '../features/home/repositories/remote_course_purchase_repository.dart';
import '../features/home/repositories/remote_home_dashboard_repository.dart';
import '../features/home/repositories/remote_message_center_repository.dart';
import '../features/home/repositories/remote_product_design_purchase_repository.dart';
import '../features/home/repositories/remote_profile_repository.dart';
import '../features/home/repositories/remote_settings_repository.dart';
import '../features/home/repositories/remote_support_repository.dart';
import '../features/home/repositories/settings_repository.dart';
import '../features/home/repositories/support_repository.dart';
import '../features/home/screens/account_menu_screens.dart';
import '../features/home/screens/course_detail_screen.dart';
import '../features/home/screens/course_payment_screen.dart';
import '../features/home/screens/course_player_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/my_courses_screen.dart';
import '../features/home/screens/product_design_course_screen.dart';
import '../features/home/screens/product_design_payment_screen.dart';
import '../features/home/screens/product_design_player_screen.dart';
import '../features/home/screens/support_content_screens.dart';
import '../features/onboarding/controllers/onboarding_controller.dart';
import '../features/onboarding/repositories/local_onboarding_content_repository.dart';
import '../features/onboarding/repositories/onboarding_content_repository.dart';
import '../features/onboarding/repositories/remote_onboarding_content_repository.dart';
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
        if (!Get.isRegistered<LocalAuthSessionRepository>()) {
          Get.put<LocalAuthSessionRepository>(
            LocalAuthSessionRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalProfileRepository>()) {
          Get.put<LocalProfileRepository>(
            LocalProfileRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalMessageCenterRepository>()) {
          Get.put<LocalMessageCenterRepository>(
            LocalMessageCenterRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalProductDesignPurchaseRepository>()) {
          Get.put<LocalProductDesignPurchaseRepository>(
            LocalProductDesignPurchaseRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalSupportRepository>()) {
          Get.put<LocalSupportRepository>(
            LocalSupportRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalCourseCatalogRepository>()) {
          Get.put<LocalCourseCatalogRepository>(
            LocalCourseCatalogRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalCoursePurchaseRepository>()) {
          Get.put<LocalCoursePurchaseRepository>(
            LocalCoursePurchaseRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalOnboardingContentRepository>()) {
          Get.put<LocalOnboardingContentRepository>(
            LocalOnboardingContentRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalSettingsRepository>()) {
          Get.put<LocalSettingsRepository>(
            LocalSettingsRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<LocalHomeDashboardRepository>()) {
          Get.put<LocalHomeDashboardRepository>(
            LocalHomeDashboardRepository(),
            permanent: true,
          );
        }
        if (!Get.isRegistered<ApiClient>()) {
          final localAuthStore = Get.find<LocalAuthSessionRepository>();
          Get.put<ApiClient>(
            ApiClient(localAuthStore.loadSession),
            permanent: true,
          );
        }
        if (!Get.isRegistered<AuthSessionRepository>()) {
          Get.put<AuthSessionRepository>(
            RemoteAuthSessionRepository(
              Get.find<ApiClient>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<ProfileRepository>()) {
          Get.put<ProfileRepository>(
            RemoteProfileRepository(
              Get.find<ApiClient>(),
              Get.find<LocalProfileRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<MessageCenterRepository>()) {
          Get.put<MessageCenterRepository>(
            RemoteMessageCenterRepository(
              Get.find<ApiClient>(),
              Get.find<LocalMessageCenterRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<ProductDesignPurchaseRepository>()) {
          Get.put<ProductDesignPurchaseRepository>(
            RemoteProductDesignPurchaseRepository(
              Get.find<ApiClient>(),
              Get.find<LocalProductDesignPurchaseRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<SupportRepository>()) {
          Get.put<SupportRepository>(
            RemoteSupportRepository(Get.find<ApiClient>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<CourseCatalogRepository>()) {
          Get.put<CourseCatalogRepository>(
            RemoteCourseCatalogRepository(
              Get.find<ApiClient>(),
              Get.find<LocalCourseCatalogRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<CoursePurchaseRepository>()) {
          Get.put<CoursePurchaseRepository>(
            RemoteCoursePurchaseRepository(
              Get.find<ApiClient>(),
              Get.find<LocalCoursePurchaseRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<OnboardingContentRepository>()) {
          Get.put<OnboardingContentRepository>(
            RemoteOnboardingContentRepository(
              Get.find<ApiClient>(),
              Get.find<LocalOnboardingContentRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<SettingsRepository>()) {
          Get.put<SettingsRepository>(
            RemoteSettingsRepository(
              Get.find<ApiClient>(),
              Get.find<LocalSettingsRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<HomeDashboardRepository>()) {
          Get.put<HomeDashboardRepository>(
            RemoteHomeDashboardRepository(
              Get.find<ApiClient>(),
              Get.find<LocalHomeDashboardRepository>(),
              Get.find<LocalAuthSessionRepository>(),
            ),
            permanent: true,
          );
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
        if (!Get.isRegistered<SettingsController>()) {
          Get.put<SettingsController>(
            SettingsController(Get.find<SettingsRepository>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<HomeDashboardController>()) {
          Get.put<HomeDashboardController>(
            HomeDashboardController(Get.find<HomeDashboardRepository>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<CourseCatalogController>()) {
          Get.put<CourseCatalogController>(
            CourseCatalogController(Get.find<CourseCatalogRepository>()),
            permanent: true,
          );
        }
        if (!Get.isRegistered<CoursePurchaseController>()) {
          Get.put<CoursePurchaseController>(
            CoursePurchaseController(Get.find<CoursePurchaseRepository>()),
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
            Get.lazyPut<OnboardingController>(
              () => OnboardingController(Get.find<OnboardingContentRepository>()),
            );
          }),
        ),
        GetPage(name: AppRoutes.signUp, page: () => const SignUpScreen()),
        GetPage(name: AppRoutes.logIn, page: () => const LogInScreen()),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: AppRoutes.phoneVerification,
          page: () => const PhoneVerificationScreen(),
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => const HomeScreen(),
        ),
        GetPage(
          name: AppRoutes.myCourses,
          page: () => const MyCoursesScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<HomeDashboardController>()) {
              Get.lazyPut<HomeDashboardController>(
                () => HomeDashboardController(
                  Get.find<HomeDashboardRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.favouriteVideos,
          page: () => const FavouriteVideosScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<CourseCatalogController>()) {
              Get.lazyPut<CourseCatalogController>(
                () => CourseCatalogController(
                  Get.find<CourseCatalogRepository>(),
                ),
              );
            }
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
            if (!Get.isRegistered<HomeDashboardController>()) {
              Get.lazyPut<HomeDashboardController>(
                () => HomeDashboardController(
                  Get.find<HomeDashboardRepository>(),
                ),
              );
            }
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
            if (!Get.isRegistered<HomeDashboardController>()) {
              Get.lazyPut<HomeDashboardController>(
                () => HomeDashboardController(
                  Get.find<HomeDashboardRepository>(),
                ),
              );
            }
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
            if (!Get.isRegistered<HomeDashboardController>()) {
              Get.lazyPut<HomeDashboardController>(
                () => HomeDashboardController(
                  Get.find<HomeDashboardRepository>(),
                ),
              );
            }
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
          name: AppRoutes.courseDetail,
          page: () => const CourseDetailScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<CourseCatalogController>()) {
              Get.lazyPut<CourseCatalogController>(
                () => CourseCatalogController(
                  Get.find<CourseCatalogRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.coursePayment,
          page: () => const CoursePaymentScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<CoursePurchaseController>()) {
              Get.lazyPut<CoursePurchaseController>(
                () => CoursePurchaseController(
                  Get.find<CoursePurchaseRepository>(),
                ),
              );
            }
          }),
        ),
        GetPage(
          name: AppRoutes.coursePlayer,
          page: () => const CoursePlayerScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<CourseCatalogController>()) {
              Get.lazyPut<CourseCatalogController>(
                () => CourseCatalogController(
                  Get.find<CourseCatalogRepository>(),
                ),
              );
            }
            if (!Get.isRegistered<HomeDashboardController>()) {
              Get.lazyPut<HomeDashboardController>(
                () => HomeDashboardController(
                  Get.find<HomeDashboardRepository>(),
                ),
              );
            }
          }),
        ),
      ],
    );
  }
}
