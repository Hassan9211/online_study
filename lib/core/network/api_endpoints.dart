class ApiConfig {
  const ApiConfig._();

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _defaultBaseUrl = 'http://192.168.2.117:8000/api';

  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride;
    }
    return _defaultBaseUrl;
  }

  static const bool enableApiLogs = bool.fromEnvironment(
    'ENABLE_API_LOGS',
    defaultValue: true,
  );
  static const bool useMockPaymentMethods = bool.fromEnvironment(
    'USE_MOCK_PAYMENT_METHODS',
    defaultValue: false,
  );
  static const bool useRemoteAiGuest = bool.fromEnvironment(
    'USE_REMOTE_AI_GUEST',
    defaultValue: false,
  );
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const String _configuredProductDesignCourseId = String.fromEnvironment(
    'PRODUCT_DESIGN_COURSE_ID',
    defaultValue: '1',
  );
  static String _resolvedProductDesignCourseId = '';

  static String get configuredProductDesignCourseId =>
      _configuredProductDesignCourseId;

  static String get productDesignCourseId {
    final resolvedId = _resolvedProductDesignCourseId.trim();
    if (resolvedId.isNotEmpty) {
      return resolvedId;
    }
    return _configuredProductDesignCourseId;
  }

  static void resolveProductDesignCourse({
    String id = '',
    String title = '',
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final normalizedTitle = _normalizeProductDesignTitle(title);
    if (normalizedId == _configuredProductDesignCourseId) {
      _resolvedProductDesignCourseId = normalizedId;
      return;
    }

    if (_resolvedProductDesignCourseId == normalizedId) {
      return;
    }

    if (_resolvedProductDesignCourseId.trim().isEmpty ||
        normalizedTitle == 'product design v1.0' ||
        normalizedTitle == 'product design') {
      _resolvedProductDesignCourseId = normalizedId;
    }
  }

  static bool matchesProductDesignCourse({
    String id = '',
    String title = '',
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isNotEmpty &&
        (normalizedId == productDesignCourseId ||
            normalizedId == _configuredProductDesignCourseId)) {
      return true;
    }

    final normalizedTitle = _normalizeProductDesignTitle(title);
    return normalizedTitle == 'product design v1.0' ||
        normalizedTitle == 'product-design-v1' ||
        normalizedTitle == 'product_design_v1' ||
        normalizedTitle == 'product design';
  }

  static String _normalizeProductDesignTitle(String value) {
    return value.trim().toLowerCase();
  }
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const OnboardingEndpoints onboarding = OnboardingEndpoints._();
  static const AuthEndpoints auth = AuthEndpoints._();
  static const UserEndpoints user = UserEndpoints._();
  static const FavouriteEndpoints favourites = FavouriteEndpoints._();
  static const CourseEndpoints courses = CourseEndpoints._();
  static const PaymentEndpoints payments = PaymentEndpoints._();
  static const NotificationEndpoints notifications = NotificationEndpoints._();
  static const MessageEndpoints messages = MessageEndpoints._();
  static const SupportEndpoints support = SupportEndpoints._();
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
  final String forgotPasswordCompat = '/password/forgot';
  final String resetPasswordCompat = '/password/reset';

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
