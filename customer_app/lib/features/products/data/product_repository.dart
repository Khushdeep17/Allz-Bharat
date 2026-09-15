import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shops/data/shop_repository.dart';
import '../models/product.dart';
import 'product_repository_impl.dart';

/// Abstract contract for reading product data from Firestore.
abstract class ProductRepository {
  /// Fetches products belonging to a specific [shopId].
  /// If [activeOnly] is true, only products with `isActive == true` are returned.
  Future<List<Product>> getProductsByShop(
    String shopId, {
    bool activeOnly = true,
  });

  /// Fetches products belonging to a specific [categoryId].
  /// If [activeOnly] is true, only products with `isActive == true` are returned.
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  });

  /// Fetches a single product by its Firestore document ID.
  Future<Product?> getProductById(String id);

  /// Streams products belonging to a specific [shopId] in real-time.
  Stream<List<Product>> watchProductsByShop(
    String shopId, {
    bool activeOnly = true,
  });

  /// Streams products belonging to a specific [categoryId] in real-time.
  Stream<List<Product>> watchProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  });

  /// Streams a single product document by its ID in real-time.
  Stream<Product?> watchProductById(String id);
}

/// Provider for the [ProductRepository] interface.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirestoreProductRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for products in a specific shop.
final productsByShopProvider =
    StreamProvider.autoDispose.family<List<Product>, String>((ref, shopId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProductsByShop(shopId);
});

/// Reactive stream provider for products in a specific category.
final productsByCategoryProvider =
    StreamProvider.autoDispose.family<List<Product>, String>((ref, categoryId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProductsByCategory(categoryId);
});

/// Reactive stream provider for a specific product by ID.
final productByIdProvider =
    StreamProvider.autoDispose.family<Product?, String>((ref, id) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProductById(id);
});

/// Reactive provider combining products across all active shops for client-side search.
final allActiveProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  final shopsAsync = ref.watch(shopsStreamProvider);
  return shopsAsync.maybeWhen(
    data: (shops) {
      final allProducts = <Product>[];
      for (final shop in shops) {
        final productsAsync = ref.watch(productsByShopProvider(shop.id));
        productsAsync.whenData((products) {
          allProducts.addAll(products);
        });
      }
      return allProducts;
    },
    orElse: () => const [],
  );
});
