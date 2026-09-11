import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product item in the Firestore `products` collection.
class Product {
  final String id;
  final String shopId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool inStock;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.inStock = true,
    this.isActive = true,
    this.createdAt,
  });

  /// Creates a [Product] instance from a Map and optional document ID.
  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    final rawPrice = map['price'];
    final double parsedPrice = (rawPrice is num) ? rawPrice.toDouble() : 0.0;

    return Product(
      id: id ?? (map['id'] as String? ?? ''),
      shopId: (map['shopId'] as String? ?? '').trim(),
      categoryId: (map['categoryId'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      description: map['description'] as String?,
      price: parsedPrice,
      imageUrl: map['imageUrl'] as String?,
      inStock: (map['inStock'] as bool?) ?? true,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  /// Creates a [Product] instance from a Firestore [DocumentSnapshot].
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product.fromMap(data, id: doc.id);
  }

  /// Converts the [Product] instance into a map for Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'categoryId': categoryId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'inStock': inStock,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this [Product] with given fields updated.
  Product copyWith({
    String? id,
    String? shopId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? inStock,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      inStock: inStock ?? this.inStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.shopId == shopId &&
        other.categoryId == categoryId &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.inStock == inStock &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      shopId.hashCode ^
      categoryId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      inStock.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, shopId: $shopId, categoryId: $categoryId, name: $name, price: $price, inStock: $inStock, isActive: $isActive)';
  }
}
