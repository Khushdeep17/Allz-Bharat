import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import 'category_repository.dart';

/// Firestore implementation of [CategoryRepository].
class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;

  FirestoreCategoryRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  @override
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    try {
      Query<Map<String, dynamic>> query = _categoriesCollection;
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[FirestoreCategoryRepository] getCategories error: $e');
      return [];
    }
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _categoriesCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Category.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreCategoryRepository] getCategoryById error: $e');
      return null;
    }
  }

  @override
  Stream<List<Category>> watchCategories({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _categoriesCollection;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('[FirestoreCategoryRepository] watchCategories error: $error');
      return <Category>[];
    });
  }

  @override
  Stream<Category?> watchCategoryById(String id) {
    return _categoriesCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Category.fromFirestore(doc);
    }).handleError((error) {
      debugPrint('[FirestoreCategoryRepository] watchCategoryById error: $error');
      return null;
    });
  }
}
