import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/cart/models/cart_item.dart';
import 'package:customer_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:customer_app/features/orders/data/cashfree_service.dart';
import 'package:customer_app/features/orders/data/order_repository.dart';
import 'package:customer_app/features/orders/data/payment_repository.dart';
import 'package:customer_app/features/orders/models/order.dart';
import 'package:customer_app/features/orders/models/order_delivery.dart';
import 'package:customer_app/features/orders/models/order_item.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/models/payment_session_result.dart';
import 'package:customer_app/features/orders/models/payment_status.dart';
import 'package:customer_app/features/orders/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'address_repository_test.dart';
import 'order_repository_test.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;

  @override
  final String? displayName;

  @override
  final String? email;

  FakeUser({
    this.uid = 'user_123',
    this.displayName = 'Khushdeep Singh',
    this.email = 'test@allzbharat.com',
  });
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

class FakePaymentRepository implements PaymentRepository {
  PaymentSessionResult? mockSessionResult;
  PaymentVerificationResult? mockVerificationResult;
  bool shouldThrowOnCreate = false;
  bool shouldThrowOnVerify = false;
  int createSessionCallCount = 0;
  int verifyPaymentCallCount = 0;

  @override
  Future<PaymentSessionResult> createPaymentSession({
    required String shopId,
    required List<CartItem> items,
    required Address deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    createSessionCallCount++;
    if (shouldThrowOnCreate) {
      throw Exception('Payment gateway unavailable');
    }
    if (mockSessionResult != null) return mockSessionResult!;
    return PaymentSessionResult(
      success: true,
      orderId: 'mock_order_123',
      paymentOrderId: 'order_mock_123_456',
      paymentSessionId: 'session_mock_789',
      amount: 74.0,
      currency: 'INR',
      pricing: const OrderPricing(
        subtotal: 54.0,
        deliveryFee: 15.0,
        platformFee: 5.0,
        total: 74.0,
      ),
      message: 'Session created successfully',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String orderId,
    String? paymentOrderId,
  }) async {
    verifyPaymentCallCount++;
    if (shouldThrowOnVerify) {
      throw Exception('Network error during verification');
    }
    if (mockVerificationResult != null) return mockVerificationResult!;
    return PaymentVerificationResult(
      success: true,
      orderId: orderId,
      paymentStatus: PaymentStatus.paid,
      paymentId: 'cf_pay_999',
      paymentMethod: 'upi',
      paidAt: DateTime(2026, 9, 18, 18, 0, 0),
      message: 'Payment verified',
    );
  }
}

class FakeCashfreePaymentService implements CashfreePaymentService {
  Function(String orderId)? onVerifyCallback;
  Function(dynamic errorResponse, String orderId)? onErrorCallback;
  int startPaymentCallCount = 0;
  String? lastPaymentOrderId;
  String? lastPaymentSessionId;

  bool autoTriggerVerify = true;
  bool autoTriggerError = false;
  dynamic errorResponsePayload;

  @override
  CFEnvironment get environment => CFEnvironment.SANDBOX;

  @override
  void setCallbacks({
    required Function(String orderId) onVerify,
    required Function(dynamic errorResponse, String orderId) onError,
  }) {
    onVerifyCallback = onVerify;
    onErrorCallback = onError;
  }

  @override
  void startPayment({
    required String paymentOrderId,
    required String paymentSessionId,
  }) {
    startPaymentCallCount++;
    lastPaymentOrderId = paymentOrderId;
    lastPaymentSessionId = paymentSessionId;

    if (autoTriggerVerify && onVerifyCallback != null) {
      onVerifyCallback!(paymentOrderId);
    } else if (autoTriggerError && onErrorCallback != null) {
      onErrorCallback!(
        errorResponsePayload ?? 'Payment cancelled by user',
        paymentOrderId,
      );
    }
  }
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

  GoRouter createTestRouter({
    required Widget home,
  }) {
    return GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (context, state) => home,
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (context, state) => OrderDetailsScreen(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/addresses',
          builder: (context, state) =>
              const Scaffold(body: Text('Addresses Screen')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) =>
              const Scaffold(body: Text('Cart Screen')),
        ),
      ],
    );
  }

  Widget createWidgetUnderTest({
    required Widget child,
    required List<Override> overrides,
  }) {
    final router = createTestRouter(home: child);
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
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
      final fakePaymentRepo = FakePaymentRepository();
      final fakeCashfreeService = FakeCashfreePaymentService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
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

      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
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

      // Check Pay & Place Order button
      expect(find.text('Pay & Place Order'), findsOneWidget);
    });

    testWidgets(
        'A. Checkout with no default address prompts to add address when Pay & Place Order is tapped',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [], // No address
      });
      final fakePaymentRepo = FakePaymentRepository();
      final fakeCashfreeService = FakeCashfreePaymentService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 1);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Please add a delivery address to place your order.'),
        findsOneWidget,
      );

      // Payment session must NOT be created
      expect(fakePaymentRepo.createSessionCallCount, 0);
    });

    testWidgets(
        'H. Successful payment initialization, SDK completion and backend verification clears cart and navigates to order details',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      final fakeCashfreeService = FakeCashfreePaymentService();
      final fakeOrderRepo = FakeOrderRepository();

      // Pre-seed the order in fakeOrderRepo so OrderDetailsScreen displays it
      await fakeOrderRepo.createOrder(
        const Order(
          orderId: 'mock_order_123',
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
          paymentStatus: 'paid',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).items.length, 1);

      // Tap Pay & Place Order
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pumpAndSettle();

      // Check payment repository created session
      expect(fakePaymentRepo.createSessionCallCount, 1);
      // Check Cashfree SDK launched
      expect(fakeCashfreeService.startPaymentCallCount, 1);
      // Check verifyPayment called
      expect(fakePaymentRepo.verifyPaymentCallCount, 1);

      // Cart MUST be cleared ONLY after verified paid status
      expect(container.read(cartProvider).items, isEmpty);
      expect(container.read(cartProvider).shopId, isNull);

      // Verify navigation to Order Details Screen
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.textContaining('Order #'), findsOneWidget);
    });

    testWidgets('C. Cart remains intact when payment session creation fails',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      fakePaymentRepo.shouldThrowOnCreate = true; // Simulate failure
      final fakeCashfreeService = FakeCashfreePaymentService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay & Place Order
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify failure SnackBar is shown
      expect(find.textContaining('Payment failed'), findsOneWidget);

      // Cashfree SDK must not be launched
      expect(fakeCashfreeService.startPaymentCallCount, 0);

      // Cart MUST remain intact with 1 item of quantity 2
      expect(container.read(cartProvider).items.length, 1);
      expect(container.read(cartProvider).items.first.quantity, 2);
      expect(container.read(cartProvider).shopId, 'shop_001');
    });

    testWidgets(
        'D & E. Cart remains intact when Cashfree SDK triggers error/cancelled callback',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      final fakeCashfreeService = FakeCashfreePaymentService();
      fakeCashfreeService.autoTriggerVerify = false;
      fakeCashfreeService.autoTriggerError = true; // Trigger SDK cancellation

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay & Place Order
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify cancellation SnackBar is shown
      expect(
        find.textContaining('Payment was cancelled or failed'),
        findsOneWidget,
      );

      // verifyPayment must not have been called
      expect(fakePaymentRepo.verifyPaymentCallCount, 0);

      // Cart MUST remain intact
      expect(container.read(cartProvider).items.length, 1);
      expect(container.read(cartProvider).items.first.quantity, 2);
    });

    testWidgets(
        'F. Cart remains intact when SDK reports success but backend verification fails',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      fakePaymentRepo.mockVerificationResult = const PaymentVerificationResult(
        success: false,
        orderId: 'mock_order_123',
        paymentStatus: PaymentStatus.failed,
        message: 'Payment verification failed at gateway.',
      );
      final fakeCashfreeService = FakeCashfreePaymentService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay & Place Order
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify failure message
      expect(
        find.textContaining('Payment verification failed at gateway'),
        findsOneWidget,
      );

      // Cart MUST NOT be cleared
      expect(container.read(cartProvider).items.length, 1);
    });

    testWidgets(
        'G. Cart remains intact when backend returns pending verification status',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      fakePaymentRepo.mockVerificationResult = const PaymentVerificationResult(
        success: false,
        orderId: 'mock_order_123',
        paymentStatus: PaymentStatus.pending,
        message: 'Payment is pending.',
      );
      final fakeCashfreeService = FakeCashfreePaymentService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay & Place Order
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify pending notification
      expect(
        find.textContaining('Payment verification is still in progress'),
        findsOneWidget,
      );

      // Cart MUST NOT be cleared
      expect(container.read(cartProvider).items.length, 1);
    });

    testWidgets('I. Duplicate tap while submitting does not trigger duplicate session creations',
        (tester) async {
      final fakeShopRepo = FakeShopRepository({'shop_001': testShop});
      final fakeAddressRepo = FakeAddressRepository({
        'user_123': [testAddress],
      });
      final fakePaymentRepo = FakePaymentRepository();
      // Disable autoTrigger to keep in submitting state
      final fakeCashfreeService = FakeCashfreePaymentService();
      fakeCashfreeService.autoTriggerVerify = false;

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(testUser)),
          userRepositoryProvider.overrideWithValue(
              FakeUserRepository({'user_123': testAppUser})),
          shopRepositoryProvider.overrideWithValue(fakeShopRepo),
          addressRepositoryProvider.overrideWithValue(fakeAddressRepo),
          paymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          cashfreePaymentServiceProvider
              .overrideWithValue(fakeCashfreeService),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct1, 2);
      final router = createTestRouter(home: const CheckoutScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay & Place Order once
      await tester.tap(find.text('Pay & Place Order'));
      await tester.pump();

      // Button is now submitting (shows spinner)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt tapping the button area again while disabled
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // createPaymentSession was called exactly once
      expect(fakePaymentRepo.createSessionCallCount, 1);
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
          paymentStatus: 'paid',
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
