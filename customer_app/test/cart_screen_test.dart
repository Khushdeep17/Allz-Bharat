import 'package:customer_app/core/routing/app_router.dart';
import 'package:customer_app/core/routing/app_routes.dart';
import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:customer_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:customer_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:customer_app/features/home/presentation/home_screen.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'address_repository_test.dart';

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
  }) async {}

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

  FakeUserRepository([Map<String, AppUser>? initialUsers]) {
    if (initialUsers != null) {
      _users.addAll(initialUsers);
    }
  }

  @override
  Future<bool> checkUserProfileExists(String uid) async =>
      _users.containsKey(uid);

  @override
  Future<AppUser?> getUserProfile(String uid) async => _users[uid];

  @override
  Future<void> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String name,
  }) async {
    _users[uid] = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) =>
      Stream.value(_users[uid]);
}

class FakeShopRepository implements ShopRepository {
  final List<Shop> _shops;

  FakeShopRepository([this._shops = const []]);

  @override
  Future<List<Shop>> getShops({bool activeOnly = true}) async => _shops;

  @override
  Future<Shop?> getShopById(String id) async {
    try {
      return _shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Shop>> watchShops({bool activeOnly = true}) =>
      Stream.value(_shops);

  @override
  Stream<Shop?> watchShopById(String id) {
    try {
      return Stream.value(_shops.firstWhere((s) => s.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

void main() {
  const testShop = Shop(
    id: 'shop_001',
    name: 'Sharma Kirana Store',
    address: 'Shastri Nagar, Meerut',
    rating: 4.2,
    isOpen: true,
    isActive: true,
  );

  const testProduct1 = Product(
    id: 'prod_001',
    shopId: 'shop_001',
    categoryId: 'cat_dairy',
    name: 'Amul Taaza Milk 500ml',
    price: 28.0,
    inStock: true,
    isActive: true,
  );

  const testProduct2 = Product(
    id: 'prod_002',
    shopId: 'shop_001',
    categoryId: 'cat_snacks',
    name: 'Parle-G 100g',
    price: 10.0,
    inStock: true,
    isActive: true,
  );

  testWidgets('CartScreen displays empty state when cart has no items',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
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

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Browse Shops'), findsOneWidget);
    expect(find.text('Total Amount'), findsNothing);

    // Tap "Browse Shops" -> navigates to Home
    await tester.tap(find.text('Browse Shops'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'CartScreen displays populated items, shop subtitle, unit prices and total amount',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
      ],
    );

    // Pre-populate cart with 2 products
    final cartNotifier = container.read(cartProvider.notifier);
    cartNotifier.addItem(testProduct1, 2); // 2 * 28 = 56
    cartNotifier.addItem(testProduct2, 1); // 1 * 10 = 10 (Total = 66)

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Ordering from Sharma Kirana Store'), findsOneWidget);

    // Product 1
    expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
    expect(find.text('Unit Price: ₹28'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹56'), findsOneWidget);

    // Product 2
    expect(find.text('Parle-G 100g'), findsOneWidget);
    expect(find.text('Unit Price: ₹10'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('₹10'), findsOneWidget);

    // Total Amount
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('₹66'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });

  testWidgets(
      'CartScreen quantity stepper increments and decrements quantity and recalculates totals',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
      ],
    );

    container.read(cartProvider.notifier).addItem(testProduct1, 1);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('₹28'), findsNWidgets(2)); // Item subtotal & Total amount

    // Tap '+' to increment
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹56'), findsNWidgets(2));

    // Tap '-' to decrement back to 1
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('₹28'), findsNWidgets(2));

    // Tap '-' again when quantity is 1 -> removes item and shows empty state
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets(
      'CartScreen trash icon removes item and clear button empties cart',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
      ],
    );

    container.read(cartProvider.notifier).addItem(testProduct1, 2);
    container.read(cartProvider.notifier).addItem(testProduct2, 1);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
    expect(find.text('Parle-G 100g'), findsOneWidget);

    // Tap trash icon on first item
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Amul Taaza Milk 500ml'), findsNothing);
    expect(find.text('Parle-G 100g'), findsOneWidget);
    expect(find.text('₹10'), findsNWidgets(2));

    // Tap "Clear" in AppBar
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets(
      'Tapping Proceed to Checkout with default address navigates to checkout screen',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository({
            'test-uid': [
              const Address(
                addressId: 'addr_1',
                label: 'Home',
                fullAddress: '123 Main St, Meerut',
                phoneNumber: '9876543210',
                isDefault: true,
              ),
            ],
          }),
        ),
      ],
    );

    container.read(cartProvider.notifier).addItem(testProduct1, 1);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Checkout Preview'), findsOneWidget);
  });

  testWidgets(
      'Tapping Proceed to Checkout without default address navigates to /addresses',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository({'test-uid': []}),
        ),
      ],
    );

    container.read(cartProvider.notifier).addItem(testProduct1, 1);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('My Addresses'), findsOneWidget);
    expect(find.text('Please add a delivery address to proceed to checkout'),
        findsOneWidget);
  });

  testWidgets(
      'Tapping CartBadge from HomeScreen navigates to CartScreen and preserves items',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(FakeUser()),
        ),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository({
            'test-uid': const AppUser(
              uid: 'test-uid',
              displayName: 'Test User',
            ),
          }),
        ),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
      ],
    );

    container.read(cartProvider.notifier).addItem(testProduct1, 2);

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

    expect(find.byType(HomeScreen), findsOneWidget);

    // Tap CartBadge in HomeScreen location header row
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    // Verify CartScreen is now rendered with items
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹56'), findsNWidgets(2));

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Returns to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'Unauthenticated user attempting to access /cart is redirected to login',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(null), // Unauthenticated
        ),
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository([testShop])),
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

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();

    // Unauthenticated user is redirected to PhoneLoginScreen
    expect(find.byType(CartScreen), findsNothing);
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
    expect(find.text('Enter your mobile number to get started with your neighborhood kirana orders.'), findsOneWidget);
  });
}

