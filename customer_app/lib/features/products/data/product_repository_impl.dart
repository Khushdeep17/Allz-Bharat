import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import 'product_repository.dart';

/// Firestore implementation of [ProductRepository].
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Future<List<Product>> getProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _productsCollection.where('shopId', isEqualTo: shopId);
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[FirestoreProductRepository] getProductsByShop error: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _productsCollection.where('categoryId', isEqualTo: categoryId);
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint(
          '[FirestoreProductRepository] getProductsByCategory error: $e');
      return [];
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Product.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreProductRepository] getProductById error: $e');
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query =
        _productsCollection.where('shopId', isEqualTo: shopId);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint(
          '[FirestoreProductRepository] watchProductsByShop error: $error');
      return <Product>[];
    });
  }

  @override
  Stream<List<Product>> watchProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query =
        _productsCollection.where('categoryId', isEqualTo: categoryId);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint(
          '[FirestoreProductRepository] watchProductsByCategory error: $error');
      return <Product>[];
    });
  }

  @override
  Stream<Product?> watchProductById(String id) {
    return _productsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Product.fromFirestore(doc);
    }).handleError((error) {
      debugPrint('[FirestoreProductRepository] watchProductById error: $error');
      return null;
    });
  }
}
