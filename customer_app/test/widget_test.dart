import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/features/home/presentation/home_screen.dart';
import 'package:customer_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:customer_app/features/splash/presentation/splash_screen.dart';
import 'package:customer_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen renders branding and navigates on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AllzBharatCustomerApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);

    // Tap splash screen to trigger deterministic navigation immediately
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Discover Nearby Kirana Shops'), findsOneWidget);
  });

  testWidgets('Home screen renders location, search bar, and kirana shops', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        theme: ThemeData(useMaterial3: true),
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
