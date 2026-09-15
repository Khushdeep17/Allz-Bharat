class CartItem {
  final String productId;
  final String shopId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  double get itemTotal => price * quantity;

  CartItem copyWith({
    String? productId,
    String? shopId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'shopId': shopId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          shopId == other.shopId &&
          name == other.name &&
          price == other.price &&
          imageUrl == other.imageUrl &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      productId.hashCode ^
      shopId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      quantity.hashCode;

  @override
  String toString() {
    return 'CartItem(productId: $productId, shopId: $shopId, name: $name, price: $price, quantity: $quantity)';
  }
}
