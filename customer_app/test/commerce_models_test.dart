import 'package:customer_app/features/categories/data/category_repository.dart';
import 'package:customer_app/features/categories/models/category.dart';
import 'package:customer_app/features/products/data/product_repository.dart';
import 'package:customer_app/features/products/models/product.dart';
import 'package:customer_app/features/shops/data/shop_repository.dart';
import 'package:customer_app/features/shops/models/shop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShopRepository implements ShopRepository {
  final List<Shop> _shops;

  FakeShopRepository(this._shops);

  @override
  Future<List<Shop>> getShops({bool activeOnly = true}) async {
    if (activeOnly) {
      return _shops.where((s) => s.isActive).toList();
    }
    return _shops;
  }

  @override
  Future<Shop?> getShopById(String id) async {
    try {
      return _shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Shop>> watchShops({bool activeOnly = true}) {
    return Stream.value(
      activeOnly ? _shops.where((s) => s.isActive).toList() : _shops,
    );
  }

  @override
  Stream<Shop?> watchShopById(String id) {
    try {
      return Stream.value(_shops.firstWhere((s) => s.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories;

  FakeCategoryRepository(this._categories);

  @override
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    if (activeOnly) {
      return _categories.where((c) => c.isActive).toList();
    }
    return _categories;
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Category>> watchCategories({bool activeOnly = true}) {
    return Stream.value(
      activeOnly
          ? _categories.where((c) => c.isActive).toList()
          : _categories,
    );
  }

  @override
  Stream<Category?> watchCategoryById(String id) {
    try {
      return Stream.value(_categories.firstWhere((c) => c.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

class FakeProductRepository implements ProductRepository {
  final List<Product> _products;

  FakeProductRepository(this._products);

  @override
  Future<List<Product>> getProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) async {
    var list = _products.where((p) => p.shopId == shopId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return list.toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) async {
    var list = _products.where((p) => p.categoryId == categoryId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return list.toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProductsByShop(
    String shopId, {
    bool activeOnly = true,
  }) {
    var list = _products.where((p) => p.shopId == shopId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return Stream.value(list.toList());
  }

  @override
  Stream<List<Product>> watchProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) {
    var list = _products.where((p) => p.categoryId == categoryId);
    if (activeOnly) {
      list = list.where((p) => p.isActive);
    }
    return Stream.value(list.toList());
  }

  @override
  Stream<Product?> watchProductById(String id) {
    try {
      return Stream.value(_products.firstWhere((p) => p.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

void main() {
  group('Shop Model Tests', () {
    test('serialization and deserialization with fromMap/toMap', () {
      final now = DateTime(2026, 3, 1, 10, 0, 0);
      final shop = Shop(
        id: 'shop_1',
        name: 'Sharma Kirana',
        address: 'Shastri Nagar, Meerut',
        imageUrl: 'https://example.com/shop.jpg',
        rating: 4.8,
        isOpen: true,
        isActive: true,
        createdAt: now,
      );

      final map = shop.toMap();
      expect(map['id'], 'shop_1');
      expect(map['name'], 'Sharma Kirana');
      expect(map['address'], 'Shastri Nagar, Meerut');
      expect(map['imageUrl'], 'https://example.com/shop.jpg');
      expect(map['rating'], 4.8);
      expect(map['isOpen'], true);
      expect(map['isActive'], true);
      expect(map['createdAt'], now.toIso8601String());

      final fromMapShop = Shop.fromMap(map);
      expect(fromMapShop.id, 'shop_1');
      expect(fromMapShop.name, 'Sharma Kirana');
      expect(fromMapShop.address, 'Shastri Nagar, Meerut');
      expect(fromMapShop.imageUrl, 'https://example.com/shop.jpg');
      expect(fromMapShop.rating, 4.8);
      expect(fromMapShop.isOpen, true);
      expect(fromMapShop.isActive, true);
      expect(fromMapShop.createdAt, now);
      expect(fromMapShop, equals(shop));
    });

    test('fromMap handles missing/default values cleanly', () {
      final shop = Shop.fromMap({
        'name': 'Gupta Store',
        'address': 'Market Road',
      }, id: 'shop_doc_1');

      expect(shop.id, 'shop_doc_1');
      expect(shop.name, 'Gupta Store');
      expect(shop.address, 'Market Road');
      expect(shop.imageUrl, isNull);
      expect(shop.rating, 0.0);
      expect(shop.isOpen, true);
      expect(shop.isActive, true);
      expect(shop.createdAt, isNull);
    });

    test('copyWith works correctly', () {
      const shop = Shop(
        id: 'shop_1',
        name: 'Original',
        address: 'Road A',
      );

      final updated = shop.copyWith(name: 'Updated', isOpen: false);
      expect(updated.id, 'shop_1');
      expect(updated.name, 'Updated');
      expect(updated.address, 'Road A');
      expect(updated.isOpen, false);
    });
  });

  group('Category Model Tests', () {
    test('serialization and deserialization with fromMap/toMap', () {
      const category = Category(
        id: 'cat_dairy',
        name: 'Dairy',
        icon: 'dairy_bottle',
        isActive: true,
      );

      final map = category.toMap();
      expect(map['id'], 'cat_dairy');
      expect(map['name'], 'Dairy');
      expect(map['icon'], 'dairy_bottle');
      expect(map['isActive'], true);

      final fromMapCat = Category.fromMap(map);
      expect(fromMapCat.id, 'cat_dairy');
      expect(fromMapCat.name, 'Dairy');
      expect(fromMapCat.icon, 'dairy_bottle');
      expect(fromMapCat.isActive, true);
      expect(fromMapCat, equals(category));
    });

    test('copyWith works correctly', () {
      const category = Category(
        id: 'cat_1',
        name: 'Grains',
        icon: 'grain',
      );

      final updated = category.copyWith(name: 'Atta & Rice', isActive: false);
      expect(updated.id, 'cat_1');
      expect(updated.name, 'Atta & Rice');
      expect(updated.icon, 'grain');
      expect(updated.isActive, false);
    });
  });

  group('Product Model Tests', () {
    test('serialization and deserialization with fromMap/toMap', () {
      final now = DateTime(2026, 3, 1, 12, 0, 0);
      final product = Product(
        id: 'prod_1',
        shopId: 'shop_1',
        categoryId: 'cat_dairy',
        name: 'Amul Taza Milk 500ml',
        description: 'Fresh toned milk',
        price: 27.0,
        imageUrl: 'https://example.com/milk.jpg',
        inStock: true,
        isActive: true,
        createdAt: now,
      );

      final map = product.toMap();
      expect(map['id'], 'prod_1');
      expect(map['shopId'], 'shop_1');
      expect(map['categoryId'], 'cat_dairy');
      expect(map['name'], 'Amul Taza Milk 500ml');
      expect(map['description'], 'Fresh toned milk');
      expect(map['price'], 27.0);
      expect(map['imageUrl'], 'https://example.com/milk.jpg');
      expect(map['inStock'], true);
      expect(map['isActive'], true);
      expect(map['createdAt'], now.toIso8601String());

      final fromMapProduct = Product.fromMap(map);
      expect(fromMapProduct.id, 'prod_1');
      expect(fromMapProduct.shopId, 'shop_1');
      expect(fromMapProduct.categoryId, 'cat_dairy');
      expect(fromMapProduct.name, 'Amul Taza Milk 500ml');
      expect(fromMapProduct.description, 'Fresh toned milk');
      expect(fromMapProduct.price, 27.0);
      expect(fromMapProduct.inStock, true);
      expect(fromMapProduct.isActive, true);
      expect(fromMapProduct.createdAt, now);
      expect(fromMapProduct, equals(product));
    });

    test('fromMap parses integer price to double cleanly', () {
      final product = Product.fromMap({
        'id': 'prod_2',
        'shopId': 'shop_1',
        'categoryId': 'cat_spices',
        'name': 'Turmeric Powder 100g',
        'price': 45, // int instead of double
      });

      expect(product.price, 45.0);
      expect(product.inStock, true);
      expect(product.isActive, true);
    });

    test('copyWith works correctly', () {
      const product = Product(
        id: 'prod_1',
        shopId: 'shop_1',
        categoryId: 'cat_1',
        name: 'Sugar 1kg',
        price: 44.0,
      );

      final updated = product.copyWith(price: 42.0, inStock: false);
      expect(updated.id, 'prod_1');
      expect(updated.price, 42.0);
      expect(updated.inStock, false);
    });
  });

  group('Repository Riverpod Provider Contracts Tests', () {
    test('ShopRepository reads active and inactive shops correctly', () async {
      final container = ProviderContainer(
        overrides: [
          shopRepositoryProvider.overrideWithValue(
            FakeShopRepository([
              const Shop(id: 's1', name: 'Active Shop', address: 'A', isActive: true),
              const Shop(id: 's2', name: 'Inactive Shop', address: 'B', isActive: false),
            ]),
          ),
        ],
      );

      final repo = container.read(shopRepositoryProvider);
      final activeShops = await repo.getShops(activeOnly: true);
      final allShops = await repo.getShops(activeOnly: false);
      final singleShop = await repo.getShopById('s1');

      expect(activeShops.length, 1);
      expect(activeShops.first.id, 's1');
      expect(allShops.length, 2);
      expect(singleShop?.name, 'Active Shop');
    });

    test('CategoryRepository reads categories correctly', () async {
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository([
              const Category(id: 'c1', name: 'Dairy', icon: 'milk', isActive: true),
              const Category(id: 'c2', name: 'Snacks', icon: 'cookie', isActive: false),
            ]),
          ),
        ],
      );

      final repo = container.read(categoryRepositoryProvider);
      final activeCategories = await repo.getCategories(activeOnly: true);
      final allCategories = await repo.getCategories(activeOnly: false);

      expect(activeCategories.length, 1);
      expect(activeCategories.first.id, 'c1');
      expect(allCategories.length, 2);
    });

    test('ProductRepository reads products by shop and category', () async {
      final container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository([
              const Product(
                id: 'p1',
                shopId: 's1',
                categoryId: 'c1',
                name: 'Milk',
                price: 30.0,
                isActive: true,
              ),
              const Product(
                id: 'p2',
                shopId: 's1',
                categoryId: 'c2',
                name: 'Chips',
                price: 10.0,
                isActive: true,
              ),
              const Product(
                id: 'p3',
                shopId: 's2',
                categoryId: 'c1',
                name: 'Curd',
                price: 25.0,
                isActive: false,
              ),
            ]),
          ),
        ],
      );

      final repo = container.read(productRepositoryProvider);
      final shop1Products = await repo.getProductsByShop('s1');
      final cat1Products = await repo.getProductsByCategory('c1', activeOnly: false);
      final cat1ActiveProducts = await repo.getProductsByCategory('c1', activeOnly: true);

      expect(shop1Products.length, 2);
      expect(cat1Products.length, 2);
      expect(cat1ActiveProducts.length, 1);
      expect(cat1ActiveProducts.first.id, 'p1');
    });
  });
}
