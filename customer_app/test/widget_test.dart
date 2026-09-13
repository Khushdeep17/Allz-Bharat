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
import 'package:customer_app/features/products/data/product_repository.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:customer_app/features/shops/presentation/screens/shop_details_screen.dart';
import 'package:customer_app/features/splash/presentation/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser({this.uid = 'test-uid'});
}

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

class FakeProductRepository implements ProductRepository {
  final List<Product> _products;
  final bool _throwError;

  FakeProductRepository([
    this._products = const [],
    this._throwError = false,
  ]);

  @override
  Future<List<Product>> getProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) async {
    if (_throwError) throw Exception('Firestore error');
    var list = _products.where((p) => p.shopId == shopId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return list.toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) async {
    if (_throwError) throw Exception('Firestore error');
    var list = _products.where((p) => p.categoryId == categoryId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return list.toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    if (_throwError) throw Exception('Firestore error');
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    var list = _products.where((p) => p.shopId == shopId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return Stream.value(list.toList());
  }

  @override
  Stream<List<Product>> watchProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    var list = _products.where((p) => p.categoryId == categoryId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return Stream.value(list.toList());
  }

  @override
  Stream<Product?> watchProductById(String id) {
    if (_throwError) return Stream.error(Exception('Firestore error'));
    try {
      return Stream.value(_products.firstWhere((p) => p.id == id));
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

final testProducts = [
  const Product(
    id: 'prod_001',
    shopId: 'shop_001',
    categoryId: 'cat_dairy',
    name: 'Amul Taaza Milk 500ml',
    description: 'Fresh Amul Taaza milk 500ml pack',
    price: 28.0,
    inStock: true,
    isActive: true,
  ),
  const Product(
    id: 'prod_005',
    shopId: 'shop_001',
    categoryId: 'cat_snacks',
    name: 'Maggi Noodles 70g',
    description: 'Maggi instant noodles 70g pack',
    price: 14.0,
    inStock: false,
    isActive: true,
  ),
  const Product(
    id: 'prod_006',
    shopId: 'shop_002',
    categoryId: 'cat_dairy',
    name: 'Amul Gold Milk 500ml',
    description: 'Amul Gold milk 500ml pack',
    price: 32.0,
    inStock: true,
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
          productRepositoryProvider
              .overrideWithValue(FakeProductRepository(testProducts)),
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

  testWidgets(
      'Tapping a shop card navigates to Shop Details screen and loads shop products',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            // Authenticated user
            FakeUser(),
          ),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider
            .overrideWithValue(FakeShopRepository(testShops)),
        categoryRepositoryProvider
            .overrideWithValue(FakeCategoryRepository(testCategories)),
        productRepositoryProvider
            .overrideWithValue(FakeProductRepository(testProducts)),
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

    // Tap first Sharma Kirana Store card
    await tester.tap(find.text('Sharma Kirana Store').first);
    await tester.pumpAndSettle();

    // Verify Shop Details Screen renders
    expect(find.byType(ShopDetailsScreen), findsOneWidget);
    expect(find.text('Shop Details'), findsOneWidget);
    expect(find.text('Sharma Kirana Store'), findsOneWidget);
    expect(find.text('Available Products'), findsOneWidget);

    // Verify Sharma's products are displayed (prod_001 in stock, prod_005 out of stock)
    expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
    expect(find.text('₹28'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);

    expect(find.text('Maggi Noodles 70g'), findsOneWidget);
    expect(find.text('₹14'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);

    // Verify Gupta's product (prod_006) does NOT appear in Sharma's shop
    expect(find.text('Amul Gold Milk 500ml'), findsNothing);

    // Test Back navigation to Home
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'Shop Details screen displays Shop not found when shop ID is invalid',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository(testShops)),
          productRepositoryProvider
              .overrideWithValue(FakeProductRepository(testProducts)),
        ],
        child: const MaterialApp(
          home: ShopDetailsScreen(shopId: 'invalid_shop_id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Shop not found'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets(
      'Shop Details screen displays empty products state when shop has no products',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository(testShops)),
          productRepositoryProvider
              .overrideWithValue(FakeProductRepository([])),
        ],
        child: const MaterialApp(
          home: ShopDetailsScreen(shopId: 'shop_001'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sharma Kirana Store'), findsOneWidget);
    expect(find.text('No products listed in this shop yet.'), findsOneWidget);
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
        productRepositoryProvider
            .overrideWithValue(FakeProductRepository(testProducts)),
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
