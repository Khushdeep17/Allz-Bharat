import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'category_repository_impl.dart';

/// Abstract contract for reading category data from Firestore.
abstract class CategoryRepository {
  /// Fetches a list of categories from Firestore.
  /// If [activeOnly] is true, only categories with `isActive == true` are returned.
  Future<List<Category>> getCategories({bool activeOnly = true});

  /// Fetches a single category by its Firestore document ID.
  Future<Category?> getCategoryById(String id);

  /// Streams the list of categories in real-time.
  Stream<List<Category>> watchCategories({bool activeOnly = true});

  /// Streams a single category document by its ID in real-time.
  Stream<Category?> watchCategoryById(String id);
}

/// Provider for the [CategoryRepository] interface.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirestoreCategoryRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for active categories.
final categoriesStreamProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

/// Reactive stream provider for a specific category by ID.
final categoryByIdProvider =
    StreamProvider.autoDispose.family<Category?, String>((ref, id) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategoryById(id);
});
