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
  static const String productDetailsPattern =
      '/shop/:shopId/product/:productId';
  static String productDetails({
    required String shopId,
    required String productId,
  }) =>
      '/shop/$shopId/product/$productId';
  static const String cart = '/cart';
  static const String addresses = '/addresses';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetailsPattern = '/orders/:orderId';
  static String orderDetails(String orderId) => '/orders/$orderId';
}
