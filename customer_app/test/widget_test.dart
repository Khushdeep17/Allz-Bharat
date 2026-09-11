import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/routing/app_router.dart';
import 'package:customer_app/core/routing/app_routes.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:customer_app/features/categories/data/category_repository.dart';
import 'package:customer_app/features/categories/models/category.dart';
import 'package:customer_app/features/home/presentation/home_screen.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:customer_app/features/splash/presentation/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeAuthRepository implements AuthRepository {
  final User? _user;

  FakeAuthRepository([this._user]);

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  User? get currentUser => _user;

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

class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};
  String? createdName;

  FakeUserRepository([Map<String, AppUser>? initialUsers]) {
    if (initialUsers != null) {
      _users.addAll(initialUsers);
    }
  }

  @override
  Future<bool> checkUserProfileExists(String uid) async {
    return _users.containsKey(uid);
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    return _users[uid];
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String name,
  }) async {
    createdName = name;
    final user = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: name,
      createdAt: DateTime.now(),
    );
    _users[uid] = user;
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) {
    return Stream.value(_users[uid]);
  }
}

class FakeShopRepository implements ShopRepository {
  final List<Shop> _shops;
  final bool _throwError;

  FakeShopRepository([this._shops = const [], this._throwError = false]);

  @override
  Future<List<Shop>> getShops({bool activeOnly = true}) async {
    if (_throwError) throw Exception('Firestore error');
    return activeOnly ? _shops.where((s) => s.isActive).toList() : _shops;
  }

  @override
  Future<Shop?> getShopById(String id) async {
    if (_throwError) throw Exception('Firestore error');
    try {
      return _shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Shop>> watchShops({bool activeOnly = true}) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    return Stream.value(
      activeOnly ? _shops.where((s) => s.isActive).toList() : _shops,
    );
  }

  @override
  Stream<Shop?> watchShopById(String id) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    try {
      return Stream.value(_shops.firstWhere((s) => s.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories;
  final bool _throwError;

  FakeCategoryRepository([
    this._categories = const [],
    this._throwError = false,
  ]);

  @override
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    if (_throwError) throw Exception('Firestore error');
    return activeOnly
        ? _categories.where((c) => c.isActive).toList()
        : _categories;
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    if (_throwError) throw Exception('Firestore error');
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Category>> watchCategories({bool activeOnly = true}) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    return Stream.value(
      activeOnly
          ? _categories.where((c) => c.isActive).toList()
          : _categories,
    );
  }

  @override
  Stream<Category?> watchCategoryById(String id) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    try {
      return Stream.value(_categories.firstWhere((c) => c.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

final testShops = [
  const Shop(
    id: 'shop_001',
    name: 'Sharma Kirana Store',
    address: 'Shastri Nagar, Meerut',
    rating: 4.2,
    isOpen: true,
    isActive: true,
  ),
  const Shop(
    id: 'shop_002',
    name: 'Gupta General Store',
    address: 'Shastri Nagar, Meerut',
    rating: 4.5,
    isOpen: true,
    isActive: true,
  ),
];

final testCategories = [
  const Category(
    id: 'cat_grocery',
    name: 'Grocery',
    icon: '🛒',
    isActive: true,
  ),
  const Category(
    id: 'cat_dairy',
    name: 'Dairy',
    icon: '🥛',
    isActive: true,
  ),
];

void main() {
  test(
      'AppUser model serialization and deserialization with name and timestamps',
      () {
    final user = AppUser(
      uid: 'test-uid-123',
      phoneNumber: '+919999999999',
      displayName: 'Khushdeep',
      email: 'user@example.com',
      createdAt: DateTime(2026, 1, 1),
    );

    final map = user.toMap();
    expect(map['name'], 'Khushdeep');
    expect(map['displayName'], 'Khushdeep');

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
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
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

  testWidgets(
      'ProfileSetupScreen renders name input, validation and continue button', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/profile-setup',
      routes: [
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('What should we\ncall you?'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue without typing name
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);

    // Enter single character
    await tester.enterText(find.byType(TextFormField), 'A');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Name must be at least 2 characters'), findsOneWidget);
  });

  testWidgets(
      'Home screen renders location, search bar, categories, and kirana shops from providers',
      (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository(testShops)),
          categoryRepositoryProvider
              .overrideWithValue(FakeCategoryRepository(testCategories)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Delivering to'), findsOneWidget);
    expect(find.text('Shastri Nagar, Meerut, UP'), findsOneWidget);
    expect(find.text('Categories'), findsNWidgets(2));
    expect(find.text('Grocery'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    expect(find.text('Featured Express Stores'), findsOneWidget);
    expect(find.text('Nearby Kirana Shops'), findsOneWidget);
    expect(find.text('Sharma Kirana Store'), findsNWidgets(2));
    expect(find.text('Gupta General Store'), findsNWidgets(2));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Home screen displays empty state when no shops/categories exist',
      (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          shopRepositoryProvider.overrideWithValue(FakeShopRepository([])),
          categoryRepositoryProvider
              .overrideWithValue(FakeCategoryRepository([])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No categories available'), findsOneWidget);
    expect(find.text('No shops available in your area'), findsOneWidget);
  });

  testWidgets(
      'Home screen displays user-friendly error message when provider throws error',
      (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository([], true)),
          categoryRepositoryProvider
              .overrideWithValue(FakeCategoryRepository([], true)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load categories right now.'), findsOneWidget);
    expect(find.text('Unable to load shops right now.'), findsOneWidget);
  });

  testWidgets('Unauthenticated user navigating to home is redirected to login',
      (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(null)),
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        shopRepositoryProvider
            .overrideWithValue(FakeShopRepository(testShops)),
        categoryRepositoryProvider
            .overrideWithValue(FakeCategoryRepository(testCategories)),
      ],
    );

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byType(PhoneLoginScreen), findsOneWidget);
  });
}
