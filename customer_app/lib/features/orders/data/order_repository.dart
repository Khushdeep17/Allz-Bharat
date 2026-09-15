import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../models/order.dart';
import 'order_repository_impl.dart';

/// Abstract contract for customer order operations in Firestore.
abstract class OrderRepository {
  /// Creates a new order document in the top-level `orders` collection.
  /// Returns the Firestore-generated or assigned order ID.
  Future<String> createOrder(Order order);

  /// Fetches an order document by its ID.
  Future<Order?> getOrderById(String orderId);

  /// Streams real-time updates for an order document by its ID.
  Stream<Order?> watchOrderById(String orderId);

  /// Streams real-time updates for all orders placed by [customerId], ordered by newest first.
  Stream<List<Order>> watchCustomerOrders(String customerId);

  /// Cancels an order if it belongs to [customerId] and is currently in 'pending' status.
  Future<void> cancelOrder({
    required String orderId,
    required String customerId,
    String cancellationReason = 'Cancelled by customer',
  });
}

/// Provider for the OrderRepository interface.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for an individual order by ID.
final orderByIdStreamProvider =
    StreamProvider.autoDispose.family<Order?, String>((ref, orderId) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchOrderById(orderId);
});

/// Reactive stream provider for all orders placed by the currently authenticated customer.
final customerOrdersStreamProvider =
    StreamProvider.autoDispose<List<Order>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(const <Order>[]);
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchCustomerOrders(user.uid);
});
