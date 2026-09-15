import 'package:customer_app/features/cart/models/cart_item.dart';
import 'package:customer_app/features/cart/models/cart_state.dart';
import 'package:customer_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cart Models Unit Tests', () {
    test('CartItem serialization, equality and itemTotal', () {
      const item = CartItem(
        productId: 'prod_001',
        shopId: 'shop_001',
        name: 'Amul Milk',
        price: 28.0,
        imageUrl: 'https://example.com/milk.png',
        quantity: 2,
      );

      expect(item.itemTotal, 56.0);

      final map = item.toMap();
      final fromMapItem = CartItem.fromMap(map);

      expect(fromMapItem, equals(item));
      expect(fromMapItem.productId, 'prod_001');
      expect(fromMapItem.shopId, 'shop_001');
      expect(fromMapItem.name, 'Amul Milk');
      expect(fromMapItem.price, 28.0);
      expect(fromMapItem.quantity, 2);
    });

    test('CartState totalItems, totalPrice and isEmpty/isNotEmpty getters', () {
      const state = CartState(
        shopId: 'shop_001',
        items: [
          CartItem(
            productId: 'prod_001',
            shopId: 'shop_001',
            name: 'Amul Milk',
            price: 28.0,
            quantity: 2,
          ),
          CartItem(
            productId: 'prod_002',
            shopId: 'shop_001',
            name: 'Parle-G',
            price: 10.0,
            quantity: 3,
          ),
        ],
      );

      expect(state.totalItems, 5);
      expect(state.totalPrice, 2 * 28.0 + 3 * 10.0); // 56 + 30 = 86.0
      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
    });
  });

  group('CartController / CartNotifier Unit Tests', () {
    late ProviderContainer container;

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

    const testProductShop2 = Product(
      id: 'prod_006',
      shopId: 'shop_002',
      categoryId: 'cat_dairy',
      name: 'Amul Gold Milk 500ml',
      price: 32.0,
      inStock: true,
      isActive: true,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial cart state is empty with null shopId', () {
      final state = container.read(cartProvider);
      expect(state.shopId, isNull);
      expect(state.items, isEmpty);
      expect(container.read(cartTotalItemsProvider), 0);
      expect(container.read(cartTotalPriceProvider), 0.0);
    });

    test('Adding product to empty cart initializes shopId and item', () {
      final notifier = container.read(cartProvider.notifier);

      final result = notifier.addItem(testProduct1, 2);

      expect(result, AddToCartResult.success);

      final state = container.read(cartProvider);
      expect(state.shopId, 'shop_001');
      expect(state.items.length, 1);
      expect(state.items.first.productId, 'prod_001');
      expect(state.items.first.shopId, 'shop_001');
      expect(state.items.first.name, 'Amul Taaza Milk 500ml');
      expect(state.items.first.price, 28.0);
      expect(state.items.first.quantity, 2);
      expect(container.read(cartTotalItemsProvider), 2);
      expect(container.read(cartTotalPriceProvider), 56.0);
    });

    test('Adding same-shop product increments quantity if product already in cart',
        () {
      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(testProduct1, 1);
      final result = notifier.addItem(testProduct1, 3);

      expect(result, AddToCartResult.success);

      final state = container.read(cartProvider);
      expect(state.shopId, 'shop_001');
      expect(state.items.length, 1);
      expect(state.items.first.productId, 'prod_001');
      expect(state.items.first.quantity, 4);
      expect(container.read(cartTotalItemsProvider), 4);
      expect(container.read(cartTotalPriceProvider), 112.0);
    });

    test('Adding same-shop different product appends item to cart', () {
      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(testProduct1, 1);
      final result = notifier.addItem(testProduct2, 2);

      expect(result, AddToCartResult.success);

      final state = container.read(cartProvider);
      expect(state.shopId, 'shop_001');
      expect(state.items.length, 2);
      expect(container.read(cartTotalItemsProvider), 3);
      expect(container.read(cartTotalPriceProvider), 28.0 + 20.0);
    });

    test(
        'Adding different-shop product returns shopConflict and DOES NOT mutate state',
        () {
      final notifier = container.read(cartProvider.notifier);

      // Add item from shop_001
      notifier.addItem(testProduct1, 2);
      final originalState = container.read(cartProvider);

      // Attempt adding item from shop_002
      final result = notifier.addItem(testProductShop2, 1);

      expect(result, AddToCartResult.shopConflict);

      final currentState = container.read(cartProvider);
      expect(currentState.shopId, 'shop_001');
      expect(currentState.items.length, 1);
      expect(currentState.items.first.productId, 'prod_001');
      expect(currentState.items.first.quantity, 2);
      expect(currentState, equals(originalState));
    });

    test(
        'confirmClearAndAdd clears previous shop items and sets new shopId and product',
        () {
      final notifier = container.read(cartProvider.notifier);

      // First add shop_001 products
      notifier.addItem(testProduct1, 2);
      notifier.addItem(testProduct2, 1);
      expect(container.read(cartProvider).shopId, 'shop_001');
      expect(container.read(cartTotalItemsProvider), 3);

      // Confirm clear and add shop_002 product
      notifier.confirmClearAndAdd(testProductShop2, 2);

      final state = container.read(cartProvider);
      expect(state.shopId, 'shop_002');
      expect(state.items.length, 1);
      expect(state.items.first.productId, 'prod_006');
      expect(state.items.first.shopId, 'shop_002');
      expect(state.items.first.quantity, 2);
      expect(container.read(cartTotalItemsProvider), 2);
      expect(container.read(cartTotalPriceProvider), 64.0);
    });

    test('updateQuantity updates quantity correctly and removes item when reaching 0',
        () {
      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(testProduct1, 2);
      notifier.addItem(testProduct2, 1);

      // Update quantity of product 1 to 5
      notifier.updateQuantity('prod_001', 5);
      expect(
        container
            .read(cartProvider)
            .items
            .firstWhere((i) => i.productId == 'prod_001')
            .quantity,
        5,
      );

      // Update quantity of product 2 to 0 -> should be removed
      notifier.updateQuantity('prod_002', 0);
      expect(container.read(cartProvider).items.length, 1);
      expect(
        container
            .read(cartProvider)
            .items
            .any((i) => i.productId == 'prod_002'),
        isFalse,
      );

      // Update product 1 to -1 -> should be removed and reset shopId
      notifier.updateQuantity('prod_001', -1);
      final finalState = container.read(cartProvider);
      expect(finalState.items, isEmpty);
      expect(finalState.shopId, isNull);
    });

    test('removeItem removes item and resets shopId if cart is empty', () {
      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(testProduct1, 2);
      notifier.removeItem('prod_001');

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
      expect(state.shopId, isNull);
    });

    test('clearCart completely clears cart items and shopId', () {
      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(testProduct1, 2);
      notifier.addItem(testProduct2, 3);
      expect(container.read(cartTotalItemsProvider), 5);

      notifier.clearCart();

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
      expect(state.shopId, isNull);
      expect(container.read(cartTotalItemsProvider), 0);
      expect(container.read(cartTotalPriceProvider), 0.0);
    });

    group('setQuantity unit tests', () {
      test('setQuantity on empty cart initializes shopId and item with exact quantity', () {
        final notifier = container.read(cartProvider.notifier);

        final result = notifier.setQuantity(testProduct1, 3);
        expect(result, AddToCartResult.success);

        final state = container.read(cartProvider);
        expect(state.shopId, 'shop_001');
        expect(state.items.length, 1);
        expect(state.items.first.quantity, 3);
        expect(container.read(cartTotalItemsProvider), 3);
        expect(container.read(cartTotalPriceProvider), 84.0);
      });

      test('setQuantity on existing same-shop product updates to exact desired quantity', () {
        final notifier = container.read(cartProvider.notifier);

        // Start with quantity 1
        notifier.setQuantity(testProduct1, 1);
        expect(container.read(cartTotalItemsProvider), 1);

        // Update to quantity 3 -> MUST be 3, NOT 4
        final result = notifier.setQuantity(testProduct1, 3);
        expect(result, AddToCartResult.success);

        final state = container.read(cartProvider);
        expect(state.items.length, 1);
        expect(state.items.first.quantity, 3);
        expect(container.read(cartTotalItemsProvider), 3);
        expect(container.read(cartTotalPriceProvider), 84.0);
      });

      test('setQuantity decreases quantity (3 -> 2)', () {
        final notifier = container.read(cartProvider.notifier);

        notifier.setQuantity(testProduct1, 3);
        notifier.setQuantity(testProduct1, 2);

        final state = container.read(cartProvider);
        expect(state.items.first.quantity, 2);
        expect(container.read(cartTotalItemsProvider), 2);
        expect(container.read(cartTotalPriceProvider), 56.0);
      });

      test('setQuantity to 0 removes product from cart', () {
        final notifier = container.read(cartProvider.notifier);

        notifier.setQuantity(testProduct1, 2);
        notifier.setQuantity(testProduct1, 0);

        final state = container.read(cartProvider);
        expect(state.items, isEmpty);
        expect(state.shopId, isNull);
        expect(container.read(cartTotalItemsProvider), 0);
      });

      test('setQuantity on different-shop product triggers shopConflict and preserves cart', () {
        final notifier = container.read(cartProvider.notifier);

        notifier.setQuantity(testProduct1, 2);
        final result = notifier.setQuantity(testProductShop2, 3);

        expect(result, AddToCartResult.shopConflict);

        final state = container.read(cartProvider);
        expect(state.shopId, 'shop_001');
        expect(state.items.length, 1);
        expect(state.items.first.productId, 'prod_001');
        expect(state.items.first.quantity, 2);
      });
    });
  });
}
