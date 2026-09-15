import 'package:customer_app/core/routing/app_router.dart';
import 'package:customer_app/core/routing/app_routes.dart';
import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:customer_app/features/orders/data/order_repository.dart';
import 'package:customer_app/features/orders/models/order.dart';
import 'package:customer_app/features/orders/models/order_delivery.dart';
import 'package:customer_app/features/orders/models/order_item.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_details_screen.dart';
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

  final testProduct1 = Product(
    id: 'p1',
    shopId: 'shop_001',
    categoryId: 'cat_dairy',
    name: 'Amul Taaza Milk 500ml',
    description: 'Fresh toned milk',
    price: 27.0,
    inStock: true,
    isActive: true,
  );

  final testProduct2 = Product(
    id: 'p2',
    shopId: 'shop_001',
    categoryId: 'cat_staples',
    name: 'Aashirvaad Shudh Chakki Atta 5kg',
    description: '100% whole wheat atta',
    price: 245.0,
    inStock: true,
    isActive: true,
  );

  final testAddress = Address(
    addressId: 'addr_001',
    label: 'Home',
    fullAddress: 'Flat 402, Green Avenue, Delhi Road, Meerut',
    phoneNumber: '9876543210',
    isDefault: true,
  );

  Widget createWidgetUnderTest({
    required Widget child,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Checkout Screen and Flow Tests', () {
    testWidgets('Empty cart displays empty state on CheckoutScreen',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const CheckoutScreen(),
          overrides: [
            authRepositoryProvider
                .overrideWithValue(FakeAuthRepository(testUser)),
            userRepositoryProvider.overrideWithValue(
                FakeUserRepository({'user_123': testAppUser})),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Browse Shops'), findsOneWidget);
    });

    testWidgets(
        'Checkout Screen displays shop info, default address, items, and pricing breakdown',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakeOrderRepo = FakeOrderRepository();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      // Add items to cart
      container
          .read(cartProvider.notifier)
          .addItem(testProduct1, 2); // 27 * 2 = 54
      container
          .read(cartProvider.notifier)
          .addItem(testProduct2, 1); // 245 * 1 = 245
      // Subtotal = 299, Delivery = 15, Platform = 5, Total = 319

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check shop name
      expect(find.text('Sharma Kirana Store'), findsOneWidget);

      // Check address
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('Flat 402, Green Avenue, Delhi Road, Meerut'),
          findsOneWidget);
      expect(find.text('9876543210'), findsWidgets);

      // Check items
      expect(find.text('Order Items (2)'), findsOneWidget);
      expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('₹54'), findsOneWidget);

      expect(find.text('Aashirvaad Shudh Chakki Atta 5kg'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('₹245'), findsWidgets);

      // Check pricing breakdown
      expect(find.text('Bill Details'), findsOneWidget);
      expect(find.text('Item Subtotal'), findsOneWidget);
      expect(find.text('₹299'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('₹15'), findsOneWidget);
      expect(find.text('Platform Fee'), findsOneWidget);
      expect(find.text('₹5'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text('₹319'), findsWidgets);

      // Check Place Order button
      expect(find.text('Place Order'), findsOneWidget);
    });

    testWidgets(
        'Cart Screen Proceed to Checkout prompts to add address if no default address',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [], // No address
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
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

      expect(
        find.text('Please add a delivery address to proceed to checkout'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Placing order creates Firestore document with full snapshot and clears cart',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakeOrderRepo = FakeOrderRepository();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).items.length, 1);

      // Tap Place Order
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Check order repository has stored the order
      expect(fakeOrderRepo.store.length, 1);
      final createdOrder = fakeOrderRepo.store.values.first;

      expect(createdOrder.customerId, 'user_123');
      expect(createdOrder.shopId, 'shop_001');
      expect(createdOrder.shopName, 'Sharma Kirana Store');
      expect(createdOrder.status, 'pending');
      expect(createdOrder.items.length, 1);
      expect(createdOrder.items.first.productId, 'p1');
      expect(createdOrder.items.first.name, 'Amul Taaza Milk 500ml');
      expect(createdOrder.items.first.price, 27.0);
      expect(createdOrder.items.first.quantity, 2);
      expect(createdOrder.items.first.subtotal, 54.0);
      expect(createdOrder.delivery.addressId, 'addr_001');
      expect(createdOrder.delivery.label, 'Home');
      expect(createdOrder.delivery.fullAddress,
          'Flat 402, Green Avenue, Delhi Road, Meerut');
      expect(createdOrder.pricing.subtotal, 54.0);
      expect(createdOrder.pricing.deliveryFee, 15.0);
      expect(createdOrder.pricing.platformFee, 5.0);
      expect(createdOrder.pricing.total, 74.0);

      // Cart MUST be cleared after successful order creation
      expect(container.read(cartProvider).items, isEmpty);
      expect(container.read(cartProvider).shopId, isNull);
    });

    testWidgets('Cart remains intact when order creation fails in Firestore',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakeOrderRepo = FakeOrderRepository();
      fakeOrderRepo.shouldThrowOnCreate = true; // Simulate failure

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Place Order
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Verify failure SnackBar is shown
      expect(find.textContaining('Failed to place order'), findsOneWidget);

      // Cart MUST remain intact with 1 item of quantity 2
      expect(container.read(cartProvider).items.length, 1);
      expect(container.read(cartProvider).items.first.quantity, 2);
      expect(container.read(cartProvider).shopId, 'shop_001');
    });

    testWidgets('OrderDetailsScreen displays all order details correctly',
        (tester) async {
      final fakeOrderRepo = FakeOrderRepository();
      final orderId = await fakeOrderRepo.createOrder(
        const Order(
          orderId: 'order_test_999',
          customerId: 'user_123',
          shopId: 'shop_001',
          shopName: 'Sharma Kirana Store',
          items: [
            OrderItem(
              productId: 'p1',
              name: 'Amul Taaza Milk 500ml',
              price: 27.0,
              quantity: 2,
              subtotal: 54.0,
            ),
          ],
          delivery: OrderDelivery(
            addressId: 'addr_001',
            label: 'Home',
            fullAddress: 'Flat 402, Green Avenue, Delhi Road, Meerut',
            phoneNumber: '9876543210',
          ),
          pricing: OrderPricing(
            subtotal: 54.0,
            deliveryFee: 15.0,
            platformFee: 5.0,
            total: 74.0,
          ),
          status: 'pending',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OrderDetailsScreen(orderId: orderId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.textContaining('Order #'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Sharma Kirana Store'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('Flat 402, Green Avenue, Delhi Road, Meerut'),
          findsOneWidget);
      expect(find.text('Amul Taaza Milk 500ml'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('₹54'), findsWidgets);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('₹15'), findsOneWidget);
      expect(find.text('Platform Fee'), findsOneWidget);
      expect(find.text('₹5'), findsOneWidget);
      expect(find.text('Total Paid'), findsOneWidget);
      expect(find.text('₹74'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
    });
  });
}
