import 'cart_item.dart';

class CartState {
  final String? shopId;
  final List<CartItem> items;

  const CartState({
    this.shopId,
    this.items = const [],
  });

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get totalPrice =>
      items.fold<double>(0.0, (total, item) => total + item.itemTotal);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    String? shopId,
    bool clearShopId = false,
    List<CartItem>? items,
  }) {
    return CartState(
      shopId: clearShopId ? null : (shopId ?? this.shopId),
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartState &&
          runtimeType == other.runtimeType &&
          shopId == other.shopId &&
          _listEquals(items, other.items);

  @override
  int get hashCode => shopId.hashCode ^ items.hashCode;

  static bool _listEquals(List<CartItem> a, List<CartItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'CartState(shopId: $shopId, totalItems: $totalItems, totalPrice: $totalPrice, items: ${items.length})';
}
