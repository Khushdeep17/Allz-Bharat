import 'dart:async';

import 'package:customer_app/features/orders/data/order_repository.dart';
import 'package:customer_app/features/orders/models/order.dart';
import 'package:customer_app/features/orders/models/order_delivery.dart';
import 'package:customer_app/features/orders/models/order_item.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOrderRepository implements OrderRepository {
  final Map<String, Order> store = {};
  final Map<String, StreamController<Order?>> _orderControllers = {};
  final Map<String, StreamController<List<Order>>> _customerControllers = {};
  bool shouldThrowOnCreate = false;
  bool shouldThrowOnWatchCustomer = false;

  FakeOrderRepository([Map<String, Order>? initialData]) {
    if (initialData != null) {
      store.addAll(initialData);
    }
  }

  void _notify(String orderId, String? customerId) {
    if (_orderControllers.containsKey(orderId)) {
      _orderControllers[orderId]!.add(store[orderId]);
    }
    if (customerId != null && _customerControllers.containsKey(customerId)) {
      _customerControllers[customerId]!.add(_getCustomerOrders(customerId));
    }
  }

  List<Order> _getCustomerOrders(String customerId) {
    final userOrders = store.values
        .where((order) => order.customerId == customerId)
        .toList();

    userOrders.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate); // Descending
    });
    return userOrders;
  }

  @override
  Future<String> createOrder(Order order) async {
    if (shouldThrowOnCreate) {
      throw Exception('Firestore order creation failed');
    }

    final id = order.orderId.isNotEmpty
        ? order.orderId
        : 'order_${DateTime.now().millisecondsSinceEpoch}_${store.length + 1}';

    final toStore = order.copyWith(
      orderId: id,
      createdAt: order.createdAt ?? DateTime.now(),
    );
    store[id] = toStore;
    _notify(id, toStore.customerId);
    return id;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    return store[orderId];
  }

  @override
  Stream<Order?> watchOrderById(String orderId) {
    final controller = _orderControllers.putIfAbsent(
      orderId,
      () => StreamController<Order?>.broadcast(),
    );
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(store[orderId]);
      }
    });
    return controller.stream;
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerId) {
    if (shouldThrowOnWatchCustomer) {
      return Stream.error(Exception('Failed to fetch customer orders'));
    }
    if (customerId.trim().isEmpty) {
      return Stream.value(const <Order>[]);
    }

    final controller = _customerControllers.putIfAbsent(
      customerId,
      () => StreamController<List<Order>>.broadcast(),
    );
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(_getCustomerOrders(customerId));
      }
    });
    return controller.stream;
  }

  @override
  Future<void> cancelOrder({
    required String orderId,
    required String customerId,
    String cancellationReason = 'Cancelled by customer',
  }) async {
    if (orderId.trim().isEmpty || customerId.trim().isEmpty) {
      throw ArgumentError('Order ID and Customer ID must not be empty.');
    }

    final existing = store[orderId];
    if (existing == null) {
      throw StateError('Order not found.');
    }

    if (existing.customerId != customerId) {
      throw StateError('You are not authorized to cancel this order.');
    }

    if (existing.status != 'pending') {
      throw StateError('Only pending orders can be cancelled.');
    }

    final updated = existing.copyWith(
      status: 'cancelled',
      cancelledAt: DateTime.now(),
      cancellationReason: cancellationReason,
    );
    store[orderId] = updated;
    _notify(orderId, customerId);
  }
}

void main() {
  group('OrderRepository Fake Tests', () {
    late FakeOrderRepository repository;

    final sampleOrder = Order(
      orderId: '',
      customerId: 'user_123',
      shopId: 'shop_001',
      shopName: 'Gupta Traders',
      items: const [
        OrderItem(
          productId: 'p10',
          name: 'Fortune Mustard Oil 1L',
          price: 145.0,
          quantity: 2,
          subtotal: 290.0,
        ),
      ],
      delivery: const OrderDelivery(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: 'House 12, Meerut',
        phoneNumber: '9876543210',
      ),
      pricing: const OrderPricing(
        subtotal: 290.0,
        deliveryFee: 15.0,
        platformFee: 5.0,
        total: 310.0,
      ),
      status: 'pending',
    );

    setUp(() {
      repository = FakeOrderRepository();
    });

    test('createOrder stores order and returns unique document ID', () async {
      final orderId = await repository.createOrder(sampleOrder);
      expect(orderId, isNotEmpty);

      final fetched = await repository.getOrderById(orderId);
      expect(fetched, isNotNull);
      expect(fetched!.orderId, orderId);
      expect(fetched.customerId, 'user_123');
      expect(fetched.shopName, 'Gupta Traders');
      expect(fetched.status, 'pending');
      expect(fetched.items.length, 1);
      expect(fetched.pricing.total, 310.0);
    });

    test('Newly created order starts with pending status', () async {
      final orderId = await repository.createOrder(sampleOrder);
      final fetched = await repository.getOrderById(orderId);

      expect(fetched!.status, 'pending');
    });

    test('watchOrderById emits stream updates for order', () async {
      final orderId = await repository.createOrder(sampleOrder);
      final stream = repository.watchOrderById(orderId);

      final emitted = await stream.first;
      expect(emitted, isNotNull);
      expect(emitted!.orderId, orderId);
      expect(emitted.shopName, 'Gupta Traders');
    });

    test('getOrderById returns null for non-existent order', () async {
      final fetched = await repository.getOrderById('non_existent_id');
      expect(fetched, isNull);
    });

    test('watchCustomerOrders filters by customerId and orders newest first',
        () async {
      final orderEarlier = sampleOrder.copyWith(
        orderId: 'order_early',
        createdAt: DateTime(2026, 9, 14, 10, 0, 0),
      );
      final orderLater = sampleOrder.copyWith(
        orderId: 'order_later',
        createdAt: DateTime(2026, 9, 14, 16, 0, 0),
      );
      final otherUserOrder = sampleOrder.copyWith(
        orderId: 'order_other',
        customerId: 'user_999',
        createdAt: DateTime(2026, 9, 14, 12, 0, 0),
      );

      await repository.createOrder(orderEarlier);
      await repository.createOrder(orderLater);
      await repository.createOrder(otherUserOrder);

      final orders = await repository.watchCustomerOrders('user_123').first;

      // Should only contain user_123's orders (2 orders)
      expect(orders.length, 2);
      // Newest first
      expect(orders[0].orderId, 'order_later');
      expect(orders[1].orderId, 'order_early');
    });

    test('watchCustomerOrders returns empty list for user with no orders',
        () async {
      final orders =
          await repository.watchCustomerOrders('user_without_orders').first;
      expect(orders, isEmpty);
    });

    test('cancelOrder updates status from pending to cancelled and preserves snapshots', () async {
      final orderId = await repository.createOrder(sampleOrder);

      await repository.cancelOrder(
        orderId: orderId,
        customerId: 'user_123',
        cancellationReason: 'Cancelled by customer',
      );

      final updated = await repository.getOrderById(orderId);
      expect(updated, isNotNull);
      expect(updated!.status, 'cancelled');
      expect(updated.orderStatus, OrderStatus.cancelled);
      expect(updated.cancelledAt, isNotNull);
      expect(updated.cancellationReason, 'Cancelled by customer');

      // Preserves all existing snapshots
      expect(updated.customerId, 'user_123');
      expect(updated.shopId, 'shop_001');
      expect(updated.shopName, 'Gupta Traders');
      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'Fortune Mustard Oil 1L');
      expect(updated.delivery.fullAddress, 'House 12, Meerut');
      expect(updated.pricing.total, 310.0);
    });

    test('cancelOrder throws error when cancelling non-pending order', () async {
      final orderId = await repository.createOrder(sampleOrder);
      // Update status to confirmed
      repository.store[orderId] = repository.store[orderId]!.copyWith(status: 'confirmed');

      expect(
        () => repository.cancelOrder(
          orderId: orderId,
          customerId: 'user_123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cancelOrder throws error when customerId does not match order owner', () async {
      final orderId = await repository.createOrder(sampleOrder);

      expect(
        () => repository.cancelOrder(
          orderId: orderId,
          customerId: 'unauthorized_user',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cancelOrder throws error for non-existent order', () async {
      expect(
        () => repository.cancelOrder(
          orderId: 'missing_order_id',
          customerId: 'user_123',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
