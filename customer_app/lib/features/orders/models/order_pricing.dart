/// Snapshot of the pricing breakdown for an order.
class OrderPricing {
  /// Default placeholder delivery fee in INR for V1.
  static const double defaultDeliveryFee = 15.0;

  /// Default placeholder platform fee in INR for V1.
  static const double defaultPlatformFee = 5.0;

  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double total;

  const OrderPricing({
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.total,
  });

  /// Factory helper that calculates total from subtotal and configurable fees.
  factory OrderPricing.calculate({
    required double subtotal,
    double deliveryFee = defaultDeliveryFee,
    double platformFee = defaultPlatformFee,
  }) {
    final total = subtotal + deliveryFee + platformFee;
    return OrderPricing(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      total: total,
    );
  }

  factory OrderPricing.fromMap(Map<String, dynamic> map) {
    final subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee =
        (map['deliveryFee'] as num?)?.toDouble() ?? defaultDeliveryFee;
    final platformFee =
        (map['platformFee'] as num?)?.toDouble() ?? defaultPlatformFee;
    final total = (map['total'] as num?)?.toDouble() ??
        (subtotal + deliveryFee + platformFee);

    return OrderPricing(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      total: total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'total': total,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPricing &&
        other.subtotal == subtotal &&
        other.deliveryFee == deliveryFee &&
        other.platformFee == platformFee &&
        other.total == total;
  }

  @override
  int get hashCode =>
      subtotal.hashCode ^
      deliveryFee.hashCode ^
      platformFee.hashCode ^
      total.hashCode;
}
