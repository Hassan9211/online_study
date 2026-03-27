class ApiConfig {
  const ApiConfig._();

  // Replace this with your real API host when backend is available.
  static const String baseUrl = 'https://api.example.com';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const AuthEndpoints auth = AuthEndpoints._();
  static const UserEndpoints user = UserEndpoints._();
  static const CourseEndpoints courses = CourseEndpoints._();
  static const PaymentEndpoints payments = PaymentEndpoints._();
  static const NotificationEndpoints notifications =
      NotificationEndpoints._();
  static const MessageEndpoints messages = MessageEndpoints._();
  static const SupportEndpoints support = SupportEndpoints._();
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
  final String read = '/notifications/read';
}

class MessageEndpoints {
  const MessageEndpoints._();

  final String conversations = '/messages/conversations';
  final String aiGuestChat = '/ai/guest-chat';

  String detail(String conversationId) => '/messages/$conversationId';
}

class SupportEndpoints {
  const SupportEndpoints._();

  final String tickets = '/support/tickets';
}
