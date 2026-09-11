import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a merchant/kirana shop in the Firestore `shops` collection.
class Shop {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final double rating;
  final bool isOpen;
  final bool isActive;
  final DateTime? createdAt;

  const Shop({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.rating = 0.0,
    this.isOpen = true,
    this.isActive = true,
    this.createdAt,
  });

  /// Creates a [Shop] instance from a Map and optional document ID.
  factory Shop.fromMap(Map<String, dynamic> map, {String? id}) {
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

    final rawRating = map['rating'];
    final double parsedRating = (rawRating is num) ? rawRating.toDouble() : 0.0;

    return Shop(
      id: id ?? (map['id'] as String? ?? ''),
      name: (map['name'] as String? ?? '').trim(),
      address: (map['address'] as String? ?? '').trim(),
      imageUrl: map['imageUrl'] as String?,
      rating: parsedRating,
      isOpen: (map['isOpen'] as bool?) ?? true,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  /// Creates a [Shop] instance from a Firestore [DocumentSnapshot].
  factory Shop.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Shop.fromMap(data, id: doc.id);
  }

  /// Converts the [Shop] instance into a map for Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'rating': rating,
      'isOpen': isOpen,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this [Shop] with given fields updated.
  Shop copyWith({
    String? id,
    String? name,
    String? address,
    String? imageUrl,
    double? rating,
    bool? isOpen,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shop &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.imageUrl == imageUrl &&
        other.rating == rating &&
        other.isOpen == isOpen &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      imageUrl.hashCode ^
      rating.hashCode ^
      isOpen.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, address: $address, rating: $rating, isOpen: $isOpen, isActive: $isActive)';
  }
}
