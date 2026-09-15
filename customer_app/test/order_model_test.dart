import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/orders/models/order.dart';
import 'package:customer_app/features/orders/models/order_delivery.dart';
import 'package:customer_app/features/orders/models/order_item.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Order Models Unit Tests', () {
    final testDate = DateTime(2026, 9, 14, 15, 30, 0);

    test('OrderItem serialization and calculation', () {
      final item = OrderItem(
        productId: 'prod_1',
        name: 'Amul Taaza Milk 500ml',
        price: 27.0,
        quantity: 3,
        subtotal: 81.0,
      );

      expect(item.productId, 'prod_1');
      expect(item.name, 'Amul Taaza Milk 500ml');
      expect(item.price, 27.0);
      expect(item.quantity, 3);
      expect(item.subtotal, 81.0);

      final map = item.toMap();
      expect(map['productId'], 'prod_1');
      expect(map['name'], 'Amul Taaza Milk 500ml');
      expect(map['price'], 27.0);
      expect(map['quantity'], 3);
      expect(map['subtotal'], 81.0);

      final fromMap = OrderItem.fromMap(map);
      expect(fromMap, equals(item));
    });

    test('OrderDelivery snapshot from Address', () {
      final address = Address(
        addressId: 'addr_101',
        label: 'Home',
        fullAddress: 'Flat 402, Green Avenue, Delhi Road, Meerut',
        phoneNumber: '9876543210',
        isDefault: true,
      );

      final delivery = OrderDelivery.fromAddress(address);

      expect(delivery.addressId, 'addr_101');
      expect(delivery.label, 'Home');
      expect(delivery.fullAddress, 'Flat 402, Green Avenue, Delhi Road, Meerut');
      expect(delivery.phoneNumber, '9876543210');

      final map = delivery.toMap();
      expect(map['addressId'], 'addr_101');
      expect(map['label'], 'Home');
      expect(map['fullAddress'], 'Flat 402, Green Avenue, Delhi Road, Meerut');
      expect(map['phoneNumber'], '9876543210');

      final fromMap = OrderDelivery.fromMap(map);
      expect(fromMap, equals(delivery));
    });

    test('OrderPricing calculation with default and custom fees', () {
      // Subtotal calculation
      final pricing = OrderPricing.calculate(subtotal: 250.0);

      expect(pricing.subtotal, 250.0);
      expect(pricing.deliveryFee, 15.0);
      expect(pricing.platformFee, 5.0);
      expect(pricing.total, 270.0); // 250 + 15 + 5

      final customPricing = OrderPricing.calculate(
        subtotal: 100.0,
        deliveryFee: 20.0,
        platformFee: 2.0,
      );
      expect(customPricing.total, 122.0); // 100 + 20 + 2

      final map = pricing.toMap();
      expect(map['subtotal'], 250.0);
      expect(map['deliveryFee'], 15.0);
      expect(map['platformFee'], 5.0);
      expect(map['total'], 270.0);

      final fromMap = OrderPricing.fromMap(map);
      expect(fromMap, equals(pricing));
    });

    test('OrderStatus values and parsing', () {
      expect(OrderStatus.pending.value, 'pending');
      expect(OrderStatus.confirmed.value, 'confirmed');
      expect(OrderStatus.preparing.value, 'preparing');
      expect(OrderStatus.readyForPickup.value, 'ready_for_pickup');
      expect(OrderStatus.outForDelivery.value, 'out_for_delivery');
      expect(OrderStatus.delivered.value, 'delivered');
      expect(OrderStatus.cancelled.value, 'cancelled');
      expect(OrderStatus.rejected.value, 'rejected');

      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
      expect(OrderStatus.fromString('ready_for_pickup'), OrderStatus.readyForPickup);
      expect(OrderStatus.fromString('unknown_value'), OrderStatus.pending);
      expect(OrderStatus.fromString(null), OrderStatus.pending);
    });

    test('Order full snapshot serialization and deserialization', () {
      final order = Order(
        orderId: 'order_123',
        customerId: 'user_456',
        shopId: 'shop_789',
        shopName: 'Sharma Kirana Store',
        items: [
          const OrderItem(
            productId: 'p1',
            name: 'Aashirvaad Atta 5kg',
            price: 245.0,
            quantity: 1,
            subtotal: 245.0,
          ),
          const OrderItem(
            productId: 'p2',
            name: 'Tata Salt 1kg',
            price: 28.0,
            quantity: 2,
            subtotal: 56.0,
          ),
        ],
        delivery: const OrderDelivery(
          addressId: 'addr_101',
          label: 'Home',
          fullAddress: '123 Main Road, Meerut',
          phoneNumber: '9876543210',
        ),
        pricing: const OrderPricing(
          subtotal: 301.0,
          deliveryFee: 15.0,
          platformFee: 5.0,
          total: 321.0,
        ),
        status: 'pending',
        createdAt: testDate,
      );

      expect(order.orderId, 'order_123');
      expect(order.customerId, 'user_456');
      expect(order.shopId, 'shop_789');
      expect(order.shopName, 'Sharma Kirana Store');
      expect(order.status, 'pending');
      expect(order.orderStatus, OrderStatus.pending);
      expect(order.items.length, 2);
      expect(order.pricing.subtotal, 301.0);
      expect(order.pricing.total, 321.0);

      // Verify serialization
      final map = order.toMap();
      expect(map['customerId'], 'user_456');
      expect(map['shopId'], 'shop_789');
      expect(map['shopName'], 'Sharma Kirana Store');
      expect(map['status'], 'pending');
      expect((map['items'] as List).length, 2);
      expect((map['delivery'] as Map)['fullAddress'], '123 Main Road, Meerut');
      expect((map['pricing'] as Map)['total'], 321.0);
      expect(map['createdAt'], isA<Timestamp>());

      // Verify deserialization
      final deserialized = Order.fromMap(map, id: 'order_123');
      expect(deserialized.orderId, 'order_123');
      expect(deserialized.customerId, 'user_456');
      expect(deserialized.shopName, 'Sharma Kirana Store');
      expect(deserialized.items.length, 2);
      expect(deserialized.items[0].name, 'Aashirvaad Atta 5kg');
      expect(deserialized.items[1].name, 'Tata Salt 1kg');
      expect(deserialized.delivery.phoneNumber, '9876543210');
      expect(deserialized.pricing.total, 321.0);
      expect(deserialized.status, 'pending');
      expect(deserialized.createdAt, testDate);
    });

    test('Order copyWith and equality checks', () {
      final order1 = Order(
        orderId: 'order_1',
        customerId: 'c1',
        shopId: 's1',
        shopName: 'Shop 1',
        items: const [],
        delivery: const OrderDelivery(
          addressId: 'a1',
          label: 'Home',
          fullAddress: 'Address 1',
          phoneNumber: '1111111111',
        ),
        pricing: const OrderPricing(
          subtotal: 50.0,
          deliveryFee: 15.0,
          platformFee: 5.0,
          total: 70.0,
        ),
        status: 'pending',
      );

      final order2 = order1.copyWith(status: 'confirmed');
      expect(order2.status, 'confirmed');
      expect(order2.orderStatus, OrderStatus.confirmed);
      expect(order2.orderId, 'order_1');
      expect(order1 == order2, isFalse);
    });

    test('Order model supports optional cancellation fields and backward compatibility', () {
      final cancelDate = DateTime(2026, 9, 14, 16, 0, 0);

      // 1. Order without cancellation fields (backward compatibility)
      final mapWithoutCancellation = <String, dynamic>{
        'customerId': 'user_123',
        'shopId': 'shop_1',
        'shopName': 'Shop 1',
        'items': <dynamic>[],
        'delivery': <String, dynamic>{
          'addressId': 'a1',
          'label': 'Home',
          'fullAddress': 'Address 1',
          'phoneNumber': '1111111111',
        },
        'pricing': <String, dynamic>{
          'subtotal': 50.0,
          'deliveryFee': 15.0,
          'platformFee': 5.0,
          'total': 70.0,
        },
        'status': 'pending',
        'createdAt': Timestamp.fromDate(testDate),
      };

      final orderWithoutCancellation = Order.fromMap(mapWithoutCancellation, id: 'order_old');
      expect(orderWithoutCancellation.cancelledAt, isNull);
      expect(orderWithoutCancellation.cancellationReason, isNull);
      expect(orderWithoutCancellation.status, 'pending');

      // 2. Cancelled order serialization and deserialization
      final cancelledOrder = orderWithoutCancellation.copyWith(
        status: 'cancelled',
        cancelledAt: cancelDate,
        cancellationReason: 'Cancelled by customer',
      );

      expect(cancelledOrder.status, 'cancelled');
      expect(cancelledOrder.orderStatus, OrderStatus.cancelled);
      expect(cancelledOrder.cancelledAt, cancelDate);
      expect(cancelledOrder.cancellationReason, 'Cancelled by customer');

      final serializedMap = cancelledOrder.toMap();
      expect(serializedMap['status'], 'cancelled');
      expect(serializedMap['cancellationReason'], 'Cancelled by customer');
      expect(serializedMap['cancelledAt'], isA<Timestamp>());

      final deserializedCancelled = Order.fromMap(serializedMap, id: 'order_old');
      expect(deserializedCancelled.status, 'cancelled');
      expect(deserializedCancelled.orderStatus, OrderStatus.cancelled);
      expect(deserializedCancelled.cancelledAt, cancelDate);
      expect(deserializedCancelled.cancellationReason, 'Cancelled by customer');
    });
  });
}
