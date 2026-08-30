import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

/// Notifier that bridges Riverpod stream state to Listenable for GoRouter.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final user = authRepo.currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuthFlow =
          location == AppRoutes.login || location == AppRoutes.otp;

      // Allow splash & onboarding to display without forced redirection
      if (isSplash || isOnboarding) {
        return null;
      }

      // If user is already logged in and navigates to login/otp, send to home
      if (isLoggedIn && isAuthFlow) {
        return AppRoutes.home;
      }

      // If user is unauthenticated and tries to access protected pages (home, etc.)
      if (!isLoggedIn && !isAuthFlow) {
        return AppRoutes.login;
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
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
