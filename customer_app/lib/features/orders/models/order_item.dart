/// Snapshot of an item placed in an order.
class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final price = (map['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (map['quantity'] as num?)?.toInt() ?? 0;
    final subtotal = (map['subtotal'] as num?)?.toDouble() ?? (price * quantity);

    return OrderItem(
      productId: (map['productId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      price: price,
      quantity: quantity,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.productId == productId &&
        other.name == name &&
        other.price == price &&
        other.quantity == quantity &&
        other.subtotal == subtotal;
  }

  @override
  int get hashCode =>
      productId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      subtotal.hashCode;
}
