import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
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
      final authRepo = ref.read(authRepositoryProvider);
      final profileAsync = ref.read(currentUserProfileProvider);

      final user = authRepo.currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuthFlow =
          location == AppRoutes.login || location == AppRoutes.otp;
      final isProfileSetup = location == AppRoutes.profileSetup;

      // Allow splash & onboarding to display without forced redirection
      if (isSplash || isOnboarding) {
        return null;
      }

      // If user is unauthenticated
      if (!isLoggedIn) {
        if (isAuthFlow) {
          return null;
        }
        return AppRoutes.login;
      }

      // User is authenticated (isLoggedIn == true)
      // Check if profile exists in Firestore
      final hasProfile = profileAsync.valueOrNull != null;
      final isProfileLoaded = profileAsync.hasValue || profileAsync.hasError;

      // If profile state is still initializing, allow current step
      if (!isProfileLoaded) {
        return null;
      }

      // First-time user without a Firestore profile record
      if (!hasProfile) {
        if (isProfileSetup) {
          return null;
        }
        return AppRoutes.profileSetup;
      }

      // Returning user with an existing Firestore profile record
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
    ],
  );
});
