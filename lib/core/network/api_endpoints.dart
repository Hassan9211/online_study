class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.2.104:8000/api',
  );
  static const bool enableApiLogs = bool.fromEnvironment(
    'ENABLE_API_LOGS',
    defaultValue: true,
  );
  static const bool useMockPaymentMethods = bool.fromEnvironment(
    'USE_MOCK_PAYMENT_METHODS',
    defaultValue: false,
  );
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const String productDesignCourseId = String.fromEnvironment(
    'PRODUCT_DESIGN_COURSE_ID',
    defaultValue: 'product_design_v1',
  );
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const OnboardingEndpoints onboarding = OnboardingEndpoints._();
  static const AuthEndpoints auth = AuthEndpoints._();
  static const UserEndpoints user = UserEndpoints._();
  static const FavouriteEndpoints favourites = FavouriteEndpoints._();
  static const CourseEndpoints courses = CourseEndpoints._();
  static const PaymentEndpoints payments = PaymentEndpoints._();
  static const NotificationEndpoints notifications =
      NotificationEndpoints._();
  static const MessageEndpoints messages = MessageEndpoints._();
  static const SupportEndpoints support = SupportEndpoints._();
  static const WebRouteEndpoints web = WebRouteEndpoints._();
  static const AppPageEndpoints app = AppPageEndpoints._();
}

class OnboardingEndpoints {
  const OnboardingEndpoints._();

  final String content = '/onboarding';
}

class AuthEndpoints {
  const AuthEndpoints._();

  final String signUp = '/auth/signup';
  final String sendOtp = '/auth/send-otp';
  final String verifyOtp = '/auth/verify-otp';
  final String logIn = '/auth/login';
  final String logOut = '/auth/logout';
  final String refreshToken = '/auth/refresh-token';
  final String changePassword = '/auth/change-password';
  final String forgotPassword = '/auth/forgot-password';
  final String resetPassword = '/auth/reset-password';

  String providerRedirect(String provider) => '/auth/$provider/redirect';
  String providerCallback(String provider) => '/auth/$provider/callback';
}

class UserEndpoints {
  const UserEndpoints._();

  final String me = '/me';
  final String avatar = '/me/avatar';
  final String settings = '/me/settings';
  final String dashboard = '/home/dashboard';
  final String stats = '/me/stats';
  final String myCourses = '/me/my-courses';
  final String favourites = '/me/favourites';
}

class FavouriteEndpoints {
  const FavouriteEndpoints._();

  final String list = '/me/favourites';

  String lesson(String lessonId) => '/me/favourites/lessons/$lessonId';
}

class CourseEndpoints {
  const CourseEndpoints._();

  final String list = '/courses';
  final String categories = '/courses/categories';

  String detail(String courseId) => '/courses/$courseId';
  String lessons(String courseId) => '/courses/$courseId/lessons';
  String progress(String courseId) => '/courses/$courseId/progress';
  String purchase(String courseId) => '/courses/$courseId/purchase';
  String favourite(String courseId) => '/courses/$courseId/favourite';
  String lessonProgress(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId/progress';
}

class PaymentEndpoints {
  const PaymentEndpoints._();

  final String methods = '/payments/methods';
  final String checkout = '/payments/checkout';
  final String verifyPin = '/payments/verify-pin';

  String detail(String paymentId) => '/payments/$paymentId';
}

class NotificationEndpoints {
  const NotificationEndpoints._();

  final String list = '/notifications';
  final String unreadCount = '/notifications/unread-count';
  final String read = '/notifications/read';

  String detailRead(String notificationId) =>
      '/notifications/$notificationId/read';
}

class MessageEndpoints {
  const MessageEndpoints._();

  final String conversations = '/messages/conversations';
  final String aiGuestChat = '/ai/guest-chat';

  String detail(String conversationId) => '/messages/$conversationId';
  String send(String conversationId) => '/messages/$conversationId';
}

class SupportEndpoints {
  const SupportEndpoints._();

  final String tickets = '/support/tickets';
}

class WebRouteEndpoints {
  const WebRouteEndpoints._();

  final String root = '/';
  final String login = '/login';
  final String signUp = '/signup';
  final String forgot = '/forgot';
  final String otp = '/otp';

  String social(String provider) => '/social/$provider';
  String socialCallback(String provider) => '/social/$provider/callback';
}

class AppPageEndpoints {
  const AppPageEndpoints._();

  final String dashboard = '/app/dashboard';
  final String courses = '/app/courses';
  final String myCourses = '/app/me/courses';
  final String favorites = '/app/favorites';
  final String notifications = '/app/notifications';
  final String messages = '/app/messages';
  final String account = '/app/account';

  String courseDetail(String courseId) => '/app/courses/$courseId';
  String checkout(String courseId) => '/app/checkout/$courseId';
}
