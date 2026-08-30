import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:customer_app/features/home/presentation/home_screen.dart';
import 'package:customer_app/features/splash/presentation/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    onCodeSent('test-verification-id', 12345);
  }

  @override
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  test('AppUser model serialization and deserialization', () {
    final user = AppUser(
      uid: 'test-uid-123',
      phoneNumber: '+919999999999',
      displayName: 'Khushdeep',
      email: 'user@example.com',
      createdAt: DateTime(2026, 1, 1),
    );

    final map = user.toMap();
    final deserialized = AppUser.fromMap(map);

    expect(deserialized.uid, 'test-uid-123');
    expect(deserialized.phoneNumber, '+919999999999');
    expect(deserialized.displayName, 'Khushdeep');
    expect(deserialized.email, 'user@example.com');
  });

  testWidgets('Splash screen renders branding elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
  });

  testWidgets('PhoneLoginScreen renders phone input and action button', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const PhoneLoginScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Get OTP'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
  });

  testWidgets('Home screen renders location, search bar, and kirana shops', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Delivering to'), findsOneWidget);
    expect(find.text('Shastri Nagar, Meerut, UP'), findsOneWidget);
    expect(find.text('Categories'), findsNWidgets(2));
    expect(find.text('Featured Express Stores'), findsOneWidget);
    expect(find.text('Nearby Kirana Shops'), findsOneWidget);
    expect(find.text('Sharma General Store'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
