/// Named route constants for GoRouter.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String shopDetailsPattern = '/shop/:shopId';
  static String shopDetails(String shopId) => '/shop/$shopId';
}
