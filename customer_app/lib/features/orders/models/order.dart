import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'order_delivery.dart';
import 'order_item.dart';
import 'order_pricing.dart';
import 'order_status.dart';
import 'payment_status.dart';

/// Represents a customer order entity in Allz Bharat.
class Order {
  final String orderId;
  final String customerId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;
  final OrderDelivery delivery;
  final OrderPricing pricing;
  final String status;
  final String paymentStatus;
  final String? paymentOrderId;
  final String? paymentId;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const Order({
    required this.orderId,
    required this.customerId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.delivery,
    required this.pricing,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentOrderId,
    this.paymentId,
    this.paymentMethod,
    this.paidAt,
    this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Helper getter to convert fulfillment status string to [OrderStatus] enum.
  OrderStatus get orderStatus => OrderStatus.fromString(status);

  /// Helper getter to convert payment status string to [PaymentStatus] enum.
  PaymentStatus get paymentStatusEnum => PaymentStatus.fromString(paymentStatus);

  factory Order.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Order.fromMap(data, id: doc.id);
  }

  factory Order.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    DateTime? parsedCancelledAt;
    final rawCancelledAt = map['cancelledAt'];
    if (rawCancelledAt is Timestamp) {
      parsedCancelledAt = rawCancelledAt.toDate();
    } else if (rawCancelledAt is String) {
      parsedCancelledAt = DateTime.tryParse(rawCancelledAt);
    } else if (rawCancelledAt != null) {
      try {
        parsedCancelledAt = (rawCancelledAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCancelledAt = null;
      }
    }

    DateTime? parsedPaidAt;
    final rawPaidAt = map['paidAt'];
    if (rawPaidAt is Timestamp) {
      parsedPaidAt = rawPaidAt.toDate();
    } else if (rawPaidAt is String) {
      parsedPaidAt = DateTime.tryParse(rawPaidAt);
    } else if (rawPaidAt != null) {
      try {
        parsedPaidAt = (rawPaidAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedPaidAt = null;
      }
    }

    final rawItems = map['items'];
    final items = <OrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(OrderItem.fromMap(item));
        } else if (item is Map) {
          items.add(OrderItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final deliveryMap = map['delivery'] is Map
        ? Map<String, dynamic>.from(map['delivery'] as Map)
        : <String, dynamic>{};

    final pricingMap = map['pricing'] is Map
        ? Map<String, dynamic>.from(map['pricing'] as Map)
        : <String, dynamic>{};

    return Order(
      orderId: id ?? (map['orderId'] ?? map['id'] ?? '') as String,
      customerId: (map['customerId'] ?? '') as String,
      shopId: (map['shopId'] ?? '') as String,
      shopName: (map['shopName'] ?? '') as String,
      items: items,
      delivery: OrderDelivery.fromMap(deliveryMap),
      pricing: OrderPricing.fromMap(pricingMap),
      status: (map['status'] ?? 'pending') as String,
      paymentStatus: (map['paymentStatus'] ?? 'pending') as String,
      paymentOrderId: map['paymentOrderId'] as String?,
      paymentId: map['paymentId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      paidAt: parsedPaidAt,
      createdAt: parsedCreatedAt,
      cancelledAt: parsedCancelledAt,
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((e) => e.toMap()).toList(),
      'delivery': delivery.toMap(),
      'pricing': pricing.toMap(),
      'status': status,
      'paymentStatus': paymentStatus,
      if (paymentOrderId != null) 'paymentOrderId': paymentOrderId,
      if (paymentId != null) 'paymentId': paymentId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!)
      else
        'createdAt': FieldValue.serverTimestamp(),
      if (cancelledAt != null)
        'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancellationReason != null)
        'cancellationReason': cancellationReason,
    };
  }

  Order copyWith({
    String? orderId,
    String? customerId,
    String? shopId,
    String? shopName,
    List<OrderItem>? items,
    OrderDelivery? delivery,
    OrderPricing? pricing,
    String? status,
    String? paymentStatus,
    String? paymentOrderId,
    String? paymentId,
    String? paymentMethod,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      delivery: delivery ?? this.delivery,
      pricing: pricing ?? this.pricing,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentOrderId: paymentOrderId ?? this.paymentOrderId,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.orderId == orderId &&
        other.customerId == customerId &&
        other.shopId == shopId &&
        other.shopName == shopName &&
        other.status == status &&
        other.paymentStatus == paymentStatus &&
        other.paymentOrderId == paymentOrderId &&
        other.paymentId == paymentId &&
        other.paymentMethod == paymentMethod &&
        other.paidAt == paidAt &&
        other.delivery == delivery &&
        other.pricing == pricing &&
        other.cancelledAt == cancelledAt &&
        other.cancellationReason == cancellationReason;
  }

  @override
  int get hashCode =>
      orderId.hashCode ^
      customerId.hashCode ^
      shopId.hashCode ^
      shopName.hashCode ^
      status.hashCode ^
      paymentStatus.hashCode ^
      paymentOrderId.hashCode ^
      paymentId.hashCode ^
      paymentMethod.hashCode ^
      paidAt.hashCode ^
      delivery.hashCode ^
      pricing.hashCode ^
      cancelledAt.hashCode ^
      cancellationReason.hashCode;

  @override
  String toString() =>
      'Order(id: $orderId, customerId: $customerId, shop: $shopName, status: $status, paymentStatus: $paymentStatus, total: ${pricing.total})';
}
