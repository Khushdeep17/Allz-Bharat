import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order.dart';
import 'order_repository.dart';

/// Concrete Firestore implementation of the [OrderRepository] interface.
/// Interacts with the top-level `orders` collection.
class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  @override
  Future<String> createOrder(Order order) async {
    final docRef = order.orderId.isNotEmpty
        ? _ordersCollection.doc(order.orderId)
        : _ordersCollection.doc();

    final orderData = order.toMap();
    await docRef.set(orderData);
    return docRef.id;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    if (orderId.trim().isEmpty) return null;
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return Order.fromFirestore(doc);
  }

  @override
  Stream<Order?> watchOrderById(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _ordersCollection.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return Order.fromFirestore(snapshot);
    });
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerId) {
    if (customerId.trim().isEmpty) {
      return Stream.value(const <Order>[]);
    }

    return _ordersCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    });
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

    final docRef = _ordersCollection.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Order not found.');
      }

      final data = snapshot.data()!;
      final docCustomerId = data['customerId'] as String?;
      if (docCustomerId != customerId) {
        throw StateError('You are not authorized to cancel this order.');
      }

      final currentStatus = data['status'] as String? ?? 'pending';
      if (currentStatus != 'pending') {
        throw StateError('Only pending orders can be cancelled.');
      }

      transaction.update(docRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': cancellationReason,
      });
    });
  }
}
