import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop.dart';
import 'shop_repository_impl.dart';

/// Abstract contract for reading shop data from Firestore.
abstract class ShopRepository {
  /// Fetches a list of shops from Firestore.
  /// If [activeOnly] is true, only shops with `isActive == true` are returned.
  Future<List<Shop>> getShops({bool activeOnly = true});

  /// Fetches a single shop by its Firestore document ID.
  Future<Shop?> getShopById(String id);

  /// Streams the list of shops in real-time.
  Stream<List<Shop>> watchShops({bool activeOnly = true});

  /// Streams a single shop document by its ID in real-time.
  Stream<Shop?> watchShopById(String id);
}

/// Provider for the [ShopRepository] interface.
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return FirestoreShopRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for active shops.
final shopsStreamProvider = StreamProvider.autoDispose<List<Shop>>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.watchShops();
});

/// Reactive stream provider for a specific shop by ID.
final shopByIdProvider =
    StreamProvider.autoDispose.family<Shop?, String>((ref, id) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.watchShopById(id);
});
