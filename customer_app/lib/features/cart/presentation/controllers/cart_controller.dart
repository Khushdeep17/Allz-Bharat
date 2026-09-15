import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/models/product.dart';
import '../../models/cart_item.dart';
import '../../models/cart_state.dart';

/// Result type returned when attempting to add an item to the cart.
enum AddToCartResult {
  /// Item was successfully added or quantity incremented.
  success,

  /// The item belongs to a different shop than current cart contents.
  shopConflict,
}

/// Riverpod Notifier for single-shop in-memory cart management.
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  /// Attempts to add [product] with [quantity] to the cart.
  ///
  /// If cart already contains items from a different shop, returns [AddToCartResult.shopConflict]
  /// and does NOT mutate cart state.
  /// If [quantity] <= 0, no-op and returns [AddToCartResult.success].
  AddToCartResult addItem(Product product, int quantity) {
    if (quantity <= 0) {
      return AddToCartResult.success;
    }

    // Check single-shop constraint
    if (state.shopId != null &&
        state.shopId != product.shopId &&
        state.items.isNotEmpty) {
      return AddToCartResult.shopConflict;
    }

    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItem;
    } else {
      final newItem = CartItem(
        productId: product.id,
        shopId: product.shopId,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: quantity,
      );
      updatedItems = [...state.items, newItem];
    }

    state = state.copyWith(
      shopId: product.shopId,
      items: updatedItems,
    );

    return AddToCartResult.success;
  }

  /// Sets the exact final desired quantity for [product] in the cart.
  ///
  /// - If [quantity] <= 0, the product is removed from the cart.
  /// - If cart contains items from another shop, returns [AddToCartResult.shopConflict]
  ///   without mutating state.
  /// - If product already exists in cart, updates its quantity to [quantity].
  /// - If product is new to the cart, adds it with [quantity].
  AddToCartResult setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeItem(product.id);
      return AddToCartResult.success;
    }

    // Check single-shop constraint
    if (state.shopId != null &&
        state.shopId != product.shopId &&
        state.items.isNotEmpty) {
      return AddToCartResult.shopConflict;
    }

    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: quantity,
      );
      updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItem;
    } else {
      final newItem = CartItem(
        productId: product.id,
        shopId: product.shopId,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: quantity,
      );
      updatedItems = [...state.items, newItem];
    }

    state = state.copyWith(
      shopId: product.shopId,
      items: updatedItems,
    );

    return AddToCartResult.success;
  }

  /// Explicitly clears all existing items from the previous shop
  /// and adds [product] with [quantity] from the new shop.
  void confirmClearAndAdd(Product product, int quantity) {
    if (quantity <= 0) {
      clearCart();
      return;
    }

    final newItem = CartItem(
      productId: product.id,
      shopId: product.shopId,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: quantity,
    );

    state = CartState(
      shopId: product.shopId,
      items: [newItem],
    );
  }

  /// Removes an item completely by [productId].
  /// If the cart becomes empty, [shopId] is cleared to null.
  void removeItem(String productId) {
    final updatedItems =
        state.items.where((item) => item.productId != productId).toList();

    if (updatedItems.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  /// Updates quantity of an existing cart item by [productId].
  /// If [newQuantity] <= 0, the item is removed.
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final existingIndex =
        state.items.indexWhere((item) => item.productId == productId);
    if (existingIndex < 0) return;

    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[existingIndex] =
        updatedItems[existingIndex].copyWith(quantity: newQuantity);

    state = state.copyWith(items: updatedItems);
  }

  /// Clears the entire cart and resets shopId to null.
  void clearCart() {
    state = const CartState();
  }
}

/// Global provider for single-shop in-memory cart state.
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

/// Derived provider for total count of items in cart.
final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});

/// Derived provider for total monetary price of items in cart.
final cartTotalPriceProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalPrice;
});
