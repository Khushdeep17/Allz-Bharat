import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/screens/address_list_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/products/presentation/screens/product_details_screen.dart';
import '../../features/shops/presentation/screens/shop_details_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

/// Notifier that bridges Riverpod stream state to Listenable for GoRouter.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) {
      notifyListeners();
    });
    ref.listen(currentUserProfileProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authStateAsync = ref.read(authStateChangesProvider);
      final profileAsync = ref.read(currentUserProfileProvider);
      final location = state.matchedLocation;

      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuthFlow =
          location == AppRoutes.login || location == AppRoutes.otp;
      final isProfileSetup = location == AppRoutes.profileSetup;

      // 1. If Firebase Auth state is still initializing on startup / reload:
      // Allow the current route to stay without prematurely redirecting to login.
      if (authStateAsync.isLoading) {
        return null;
      }

      final user = authStateAsync.valueOrNull;
      final isLoggedIn = user != null;

      // 2. If user is unauthenticated
      if (!isLoggedIn) {
        if (isSplash || isOnboarding || isAuthFlow) {
          return null;
        }
        return AppRoutes.login;
      }

      // 3. User is authenticated (isLoggedIn == true)
      // If profile state is still initializing, wait for it without redirecting
      if (profileAsync.isLoading) {
        return null;
      }

      final profile = profileAsync.valueOrNull;
      final hasProfile = profile != null;

      // 4. First-time user without a Firestore profile record
      if (!hasProfile) {
        if (isProfileSetup) {
          return null;
        }
        return AppRoutes.profileSetup;
      }

      // 5. Returning user with an existing Firestore profile record
      if (isAuthFlow || isProfileSetup) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopDetailsPattern,
        builder: (context, state) {
          final shopId = state.pathParameters['shopId'] ?? '';
          return ShopDetailsScreen(shopId: shopId);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetailsPattern,
        builder: (context, state) {
          final shopId = state.pathParameters['shopId'] ?? '';
          final productId = state.pathParameters['productId'] ?? '';
          return ProductDetailsScreen(
            shopId: shopId,
            productId: productId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetailsPattern,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
    ],
  );
});
