import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shop.dart';
import 'shop_repository.dart';

/// Firestore implementation of [ShopRepository].
class FirestoreShopRepository implements ShopRepository {
  final FirebaseFirestore _firestore;

  FirestoreShopRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _firestore.collection('shops');

  @override
  Future<List<Shop>> getShops({bool activeOnly = true}) async {
    try {
      Query<Map<String, dynamic>> query = _shopsCollection;
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[FirestoreShopRepository] getShops error: $e');
      return [];
    }
  }

  @override
  Future<Shop?> getShopById(String id) async {
    try {
      final doc = await _shopsCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Shop.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreShopRepository] getShopById error: $e');
      return null;
    }
  }

  @override
  Stream<List<Shop>> watchShops({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _shopsCollection;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Shop.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('[FirestoreShopRepository] watchShops error: $error');
      return <Shop>[];
    });
  }

  @override
  Stream<Shop?> watchShopById(String id) {
    return _shopsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Shop.fromFirestore(doc);
    }).handleError((error) {
      debugPrint('[FirestoreShopRepository] watchShopById error: $error');
      return null;
    });
  }
}
