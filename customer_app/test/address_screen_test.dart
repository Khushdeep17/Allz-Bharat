import 'package:customer_app/core/routing/app_router.dart';
import 'package:customer_app/core/routing/app_routes.dart';
import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/addresses/presentation/screens/address_list_screen.dart';
import 'package:customer_app/features/addresses/presentation/widgets/address_card.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';
import 'package:customer_app/features/auth/data/user_repository.dart';
import 'package:customer_app/features/auth/models/app_user.dart';
import 'package:customer_app/features/cart/presentation/controllers/cart_controller.dart';
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
  Stream<List<Shop>> watchShops({bool activeOnly = true}) =>
      Stream.value(_shops);

  @override
  Future<Shop?> getShopById(String shopId) async {
    try {
      return _shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Shop?> watchShopById(String shopId) {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      return Stream.value(shop);
    } catch (_) {
      return Stream.value(null);
    }
  }
}

void main() {
  const testUser = AppUser(
    uid: 'test-uid',
    displayName: 'Test User',
    phoneNumber: '+919876543210',
  );

  const testShop = Shop(
    id: 'shop_001',
    name: 'Sharma Kirana Store',
    address: 'Shastri Nagar, Meerut',
    rating: 4.5,
    isActive: true,
  );

  const testProduct = Product(
    id: 'prod_001',
    shopId: 'shop_001',
    categoryId: 'cat_dairy',
    name: 'Amul Taaza Milk 500ml',
    price: 28.0,
    inStock: true,
  );

  group('Address Management Widget Tests', () {
    testWidgets('AddressListScreen displays empty state when no addresses exist',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository({'test-uid': []}),
          ),
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

      router.go(AppRoutes.addresses);
      await tester.pumpAndSettle();

      expect(find.byType(AddressListScreen), findsOneWidget);
      expect(find.text('My Addresses'), findsOneWidget);
      expect(find.text('No saved addresses yet'), findsOneWidget);
      expect(find.text('Add Address'), findsNWidgets(2)); // FAB and CTA button
    });

    testWidgets('AddressListScreen renders saved address card and default badge',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository({
              'test-uid': [
                const Address(
                  addressId: 'addr_1',
                  label: 'Home',
                  fullAddress: 'Flat 402, Royal Palms, Shastri Nagar, Meerut',
                  phoneNumber: '9876543210',
                  isDefault: true,
                ),
              ],
            }),
          ),
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

      router.go(AppRoutes.addresses);
      await tester.pumpAndSettle();

      expect(find.byType(AddressCard), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Flat 402, Royal Palms, Shastri Nagar, Meerut'),
          findsOneWidget);
      expect(find.text('Contact: 9876543210'), findsOneWidget);
    });

    testWidgets('Add Address flow opens form, validates and adds address',
        (WidgetTester tester) async {
      final fakeRepo = FakeAddressRepository({'test-uid': []});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          addressRepositoryProvider.overrideWithValue(fakeRepo),
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

      router.go(AppRoutes.addresses);
      await tester.pumpAndSettle();

      // Tap Add Address FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add New Address'), findsOneWidget);
      expect(find.text('Save Address'), findsOneWidget);

      // Try submitting empty form
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your complete delivery address'),
          findsOneWidget);
      expect(find.text('Please enter a contact phone number'), findsOneWidget);

      // Fill valid address and phone
      final textFields = find.byType(TextFormField);
      await tester.enterText(
          textFields.first, 'House No. 54, Sector 3, Meerut - 250001');
      await tester.enterText(textFields.last, '9876543210');
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      final saved = await fakeRepo.getAddresses('test-uid');
      expect(saved.length, 1);
      expect(saved.first.fullAddress,
          'House No. 54, Sector 3, Meerut - 250001');
      expect(saved.first.phoneNumber, '9876543210');
    });

    testWidgets('Edit Address flow updates existing address',
        (WidgetTester tester) async {
      final fakeRepo = FakeAddressRepository({
        'test-uid': [
          const Address(
            addressId: 'addr_1',
            label: 'Home',
            fullAddress: 'Old Address, Street 1',
            phoneNumber: '9876543210',
            isDefault: true,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          addressRepositoryProvider.overrideWithValue(fakeRepo),
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

      router.go(AppRoutes.addresses);
      await tester.pumpAndSettle();

      // Tap Edit icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Address'), findsOneWidget);
      expect(find.text('Update Address'), findsOneWidget);

      // Change address text
      final textFields = find.byType(TextFormField);
      await tester.enterText(
          textFields.first, 'Updated Address, Royal Palms, Floor 4');
      await tester.pumpAndSettle();

      // Submit update
      await tester.tap(find.text('Update Address'));
      await tester.pumpAndSettle();

      final updated = await fakeRepo.getAddresses('test-uid');
      expect(updated.length, 1);
      expect(updated.first.fullAddress,
          'Updated Address, Royal Palms, Floor 4');
    });

    testWidgets('Delete Address confirmation dialog: Cancel vs Confirm',
        (WidgetTester tester) async {
      final fakeRepo = FakeAddressRepository({
        'test-uid': [
          const Address(
            addressId: 'addr_1',
            label: 'Home',
            fullAddress: 'Flat 402, Royal Palms',
            phoneNumber: '9876543210',
            isDefault: true,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          addressRepositoryProvider.overrideWithValue(fakeRepo),
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

      router.go(AppRoutes.addresses);
      await tester.pumpAndSettle();

      // Tap Delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Delete this address?'), findsOneWidget);
      expect(find.text('This address will be permanently removed.'),
          findsOneWidget);

      // Tap Cancel -> address still exists
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      var saved = await fakeRepo.getAddresses('test-uid');
      expect(saved.length, 1);

      // Tap Delete icon again -> Confirm delete
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      saved = await fakeRepo.getAddresses('test-uid');
      expect(saved, isEmpty);
    });

    testWidgets(
        'Cart Screen Proceed to Checkout without default address redirects to /addresses',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          shopRepositoryProvider.overrideWithValue(
            FakeShopRepository([testShop]),
          ),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository({'test-uid': []}),
          ),
        ],
      );

      container.read(cartProvider.notifier).addItem(testProduct, 1);

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

      expect(find.byType(AddressListScreen), findsOneWidget);
      expect(find.text('Please add a delivery address to proceed to checkout'),
          findsOneWidget);
    });

    testWidgets(
        'Cart Screen Proceed to Checkout with default address navigates to checkout screen',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(FakeUser()),
          ),
          userRepositoryProvider.overrideWithValue(
            FakeUserRepository({'test-uid': testUser}),
          ),
          shopRepositoryProvider.overrideWithValue(
            FakeShopRepository([testShop]),
          ),
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

      container.read(cartProvider.notifier).addItem(testProduct, 1);

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
  });
}
