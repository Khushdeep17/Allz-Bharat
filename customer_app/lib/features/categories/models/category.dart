import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product category in the Firestore `categories` collection.
class Category {
  final String id;
  final String name;
  final String icon;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isActive = true,
  });

  /// Creates a [Category] instance from a Map and optional document ID.
  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
      id: id ?? (map['id'] as String? ?? ''),
      name: (map['name'] as String? ?? '').trim(),
      icon: (map['icon'] as String? ?? '').trim(),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  /// Creates a [Category] instance from a Firestore [DocumentSnapshot].
  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Category.fromMap(data, id: doc.id);
  }

  /// Converts the [Category] instance into a map for Firestore serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isActive': isActive,
    };
  }

  /// Creates a copy of this [Category] with given fields updated.
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ icon.hashCode ^ isActive.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, isActive: $isActive)';
  }
}
