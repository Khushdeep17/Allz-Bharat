import 'package:customer_app/core/routing/app_router.dart';
import 'package:customer_app/core/routing/app_routes.dart';
import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/orders/data/order_repository.dart';
import 'package:customer_app/features/orders/models/order.dart';
import 'package:customer_app/features/orders/models/order_delivery.dart';
import 'package:customer_app/features/orders/models/order_item.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/models/order_status.dart';
import 'package:customer_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:customer_app/features/products/data/product_repository.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'address_repository_test.dart';
import 'order_repository_test.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser({this.uid = 'user_123'});
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
    required String name,
    required String phoneNumber,
  }) async {
    _users[uid] = AppUser(
      uid: uid,
      displayName: name,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) {
    return Stream.value(_users[uid]);
  }
}

class FakeShopRepository implements ShopRepository {
  final Map<String, Shop> _shops = {};

  FakeShopRepository([Map<String, Shop>? initialShops]) {
    if (initialShops != null) {
      _shops.addAll(initialShops);
    }
  }

  @override
  Future<List<Shop>> getShops({bool activeOnly = true}) async =>
      _shops.values.toList();

  @override
  Future<Shop?> getShopById(String id) async => _shops[id];

  @override
  Stream<List<Shop>> watchShops({bool activeOnly = true}) =>
      Stream.value(_shops.values.toList());

  @override
  Stream<Shop?> watchShopById(String id) => Stream.value(_shops[id]);
}

class FakeProductRepository implements ProductRepository {
  final Map<String, List<Product>> _productsByShop = {};

  FakeProductRepository([Map<String, List<Product>>? initialProducts]) {
    if (initialProducts != null) {
      _productsByShop.addAll(initialProducts);
    }
  }

  @override
  Future<List<Product>> getProductsByShop(String shopId,
      {bool activeOnly = true}) async {
    return _productsByShop[shopId] ?? [];
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId,
      {bool activeOnly = true}) async {
    return [];
  }

  @override
  Future<Product?> getProductById(String id) async => null;

  @override
  Stream<List<Product>> watchProductsByShop(String shopId,
      {bool activeOnly = true}) {
    return Stream.value(_productsByShop[shopId] ?? []);
  }

  @override
  Stream<List<Product>> watchProductsByCategory(String categoryId,
      {bool activeOnly = true}) {
    return Stream.value([]);
  }

  @override
  Stream<Product?> watchProductById(String id) => Stream.value(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = FakeUser(uid: 'user_123');
  final testAppUser = AppUser(
    uid: 'user_123',
    displayName: 'Khushdeep Singh',
    phoneNumber: '+919876543210',
    createdAt: DateTime.now(),
  );

  final testShop = Shop(
    id: 'shop_001',
    name: 'Sharma Kirana Store',
    address: '123 Main Road, Meerut',
    isActive: true,
  );

  final testOrder1 = Order(
    orderId: 'order_abc12345',
    customerId: 'user_123',
    shopId: 'shop_001',
    shopName: 'Sharma Kirana Store',
    items: const [
      OrderItem(
        productId: 'p1',
        name: 'Amul Taaza Milk 500ml',
        price: 27.0,
        quantity: 2,
        subtotal: 54.0,
      ),
      OrderItem(
        productId: 'p2',
        name: 'Aashirvaad Atta 5kg',
        price: 245.0,
        quantity: 1,
        subtotal: 245.0,
      ),
    ],
    delivery: const OrderDelivery(
      addressId: 'addr_1',
      label: 'Home',
      fullAddress: 'Flat 402, Green Avenue, Meerut',
      phoneNumber: '9876543210',
    ),
    pricing: const OrderPricing(
      subtotal: 299.0,
      deliveryFee: 15.0,
      platformFee: 5.0,
      total: 319.0,
    ),
    status: 'pending',
    createdAt: DateTime(2026, 9, 14, 15, 30, 0),
  );

  final testOrder2 = Order(
    orderId: 'order_xyz67890',
    customerId: 'user_123',
    shopId: 'shop_001',
    shopName: 'Sharma Kirana Store',
    items: const [
      OrderItem(
        productId: 'p3',
        name: 'Fortune Mustard Oil 1L',
        price: 145.0,
        quantity: 1,
        subtotal: 145.0,
      ),
    ],
    delivery: const OrderDelivery(
      addressId: 'addr_1',
      label: 'Home',
      fullAddress: 'Flat 402, Green Avenue, Meerut',
      phoneNumber: '9876543210',
    ),
    pricing: const OrderPricing(
      subtotal: 145.0,
      deliveryFee: 15.0,
      platformFee: 5.0,
      total: 165.0,
    ),
    status: 'delivered',
    createdAt: DateTime(2026, 9, 13, 11, 0, 0),
  );

  group('My Orders Screen Tests', () {
    testWidgets('Orders screen displays empty state when user has no orders',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('No orders yet'), findsOneWidget);
      expect(
          find.text('Browse nearby Kirana stores and place your first order.'),
          findsOneWidget);
      expect(find.text('Browse Shops'), findsOneWidget);
    });

    testWidgets('Orders screen displays error state with retry button',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository();
      fakeOrderRepo.shouldThrowOnWatchCustomer = true;

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'Orders screen displays populated order list with all card details',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository({
        'order_abc12345': testOrder1,
        'order_xyz67890': testOrder2,
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);

      // Verify order 1 details
      expect(find.text('Sharma Kirana Store'), findsNWidgets(2));
      expect(find.textContaining('#ORDER_AB'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('₹319'), findsOneWidget);
      expect(find.textContaining('3 items • Amul Taaza Milk 500ml, Aashirvaad'),
          findsOneWidget);

      // Verify order 2 details
      expect(find.textContaining('#ORDER_XY'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('₹165'), findsOneWidget);
      expect(find.text('1 item • Fortune Mustard Oil 1L'), findsOneWidget);
    });

    testWidgets(
        'Tapping an order card navigates to OrderDetailsScreen with correct orderId',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository({
        'order_abc12345': testOrder1,
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository({'shop_001': testShop})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      router.go(AppRoutes.orders);
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Sharma Kirana Store'), findsOneWidget);

      // Tap on the order card
      await tester.tap(find.text('Sharma Kirana Store'));
      await tester.pumpAndSettle();

      // Should be on OrderDetailsScreen for order_abc12345
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.textContaining('Order #ORDER_AB'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Total Paid'), findsOneWidget);
      expect(find.text('₹319'), findsOneWidget);
    });

    testWidgets('Home screen profile sheet provides My Orders entry point',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository();
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': const [
          Address(
            addressId: 'addr_1',
            label: 'Home',
            fullAddress: '123 Main St, Meerut',
            phoneNumber: '9876543210',
            isDefault: true,
          ),
        ],
      });
      final fakeProductRepo = FakeProductRepository({'shop_001': const []});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          productRepositoryProvider.overrideWithValue(fakeProductRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      // Tap Profile tab in BottomNavigationBar (index 3)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // Verify My Orders tile exists
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('View and track your orders'), findsOneWidget);

      // Tap My Orders
      await tester.tap(find.text('My Orders'));
      await tester.pumpAndSettle();

      // Verify navigated to OrdersScreen
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('Home screen bottom navigation bar provides My Orders entry point',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository();
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': const [
          Address(
            addressId: 'addr_1',
            label: 'Home',
            fullAddress: '123 Main St, Meerut',
            phoneNumber: '9876543210',
            isDefault: true,
          ),
        ],
      });
      final fakeProductRepo = FakeProductRepository({'shop_001': const []});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          productRepositoryProvider.overrideWithValue(fakeProductRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      // Tap Orders tab in BottomNavigationBar (index 2)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
      await tester.pumpAndSettle();

      // Verify navigated to OrdersScreen
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('Order Details shows Cancel Order for pending order and hides it for non-pending orders',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository({
        'order_pending': testOrder1.copyWith(orderId: 'order_pending', status: 'pending'),
        'order_delivered': testOrder2.copyWith(orderId: 'order_delivered', status: 'delivered'),
        'order_cancelled': testOrder1.copyWith(orderId: 'order_cancelled', status: 'cancelled'),
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository({'shop_001': testShop})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      // 1. Check pending order
      router.go(AppRoutes.orderDetails('order_pending'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Order'), findsOneWidget);

      // 2. Check delivered order
      router.go(AppRoutes.orderDetails('order_delivered'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Order'), findsNothing);

      // 3. Check already cancelled order
      router.go(AppRoutes.orderDetails('order_cancelled'));
      await tester.pumpAndSettle();

      expect(find.text('Order Cancelled'), findsOneWidget);
      expect(find.text('Cancel Order'), findsNothing);
    });

    testWidgets('Cancel Order confirmation dialog: Keep Order keeps order pending',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository({
        'order_pending': testOrder1.copyWith(orderId: 'order_pending', status: 'pending'),
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository({'shop_001': testShop})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      router.go(AppRoutes.orderDetails('order_pending'));
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap Cancel Order button
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Order'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Cancel Order?'), findsOneWidget);
      expect(find.text('Are you sure you want to cancel this order?'), findsOneWidget);
      expect(find.text('Keep Order'), findsOneWidget);

      // Tap Keep Order
      await tester.tap(find.text('Keep Order'));
      await tester.pumpAndSettle();

      // Dialog dismissed, order still pending
      expect(find.text('Cancel Order?'), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
      expect(fakeOrderRepo.store['order_pending']!.status, 'pending');
    });

    testWidgets('Cancel Order flow cancels order, updates UI to Cancelled, and remains in My Orders',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository({
        'order_pending': testOrder1.copyWith(orderId: 'order_pending', status: 'pending'),
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider
              .overrideWithValue(FakeShopRepository({'shop_001': testShop})),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
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

      router.go(AppRoutes.orderDetails('order_pending'));
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap Cancel Order button on screen
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cancel Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Order'));
      await tester.pumpAndSettle();

      // Tap Cancel Order in confirmation dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Order'));
      await tester.pumpAndSettle();

      // Verify repository updated
      expect(fakeOrderRepo.store['order_pending']!.status, 'cancelled');
      expect(fakeOrderRepo.store['order_pending']!.orderStatus, OrderStatus.cancelled);

      // Verify UI updated
      expect(find.text('Order cancelled successfully'), findsOneWidget);
      expect(find.text('Order Cancelled'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      // Cancel button should no longer exist
      expect(find.widgetWithText(OutlinedButton, 'Cancel Order'), findsNothing);

      // Return to My Orders
      router.go(AppRoutes.orders);
      await tester.pumpAndSettle();

      // Order should still be in list with Cancelled status
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Sharma Kirana Store'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });
}
