import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer delivery address entity in Allz Bharat.
class Address {
  final String addressId;
  final String label;
  final String fullAddress;
  final String phoneNumber;
  final bool isDefault;
  final DateTime? createdAt;

  const Address({
    required this.addressId,
    required this.label,
    required this.fullAddress,
    required this.phoneNumber,
    this.isDefault = false,
    this.createdAt,
  });

  factory Address.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Address.fromMap(data, id: doc.id);
  }

  factory Address.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    return Address(
      addressId: id ?? (map['addressId'] ?? map['id'] ?? '') as String,
      label: (map['label'] ?? '') as String,
      fullAddress: (map['fullAddress'] ?? map['address'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? map['phone'] ?? '') as String,
      isDefault: (map['isDefault'] ?? false) as bool,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!)
      else
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Address copyWith({
    String? addressId,
    String? label,
    String? fullAddress,
    String? phoneNumber,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      addressId: addressId ?? this.addressId,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.addressId == addressId &&
        other.label == label &&
        other.fullAddress == fullAddress &&
        other.phoneNumber == phoneNumber &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode =>
      addressId.hashCode ^
      label.hashCode ^
      fullAddress.hashCode ^
      phoneNumber.hashCode ^
      isDefault.hashCode;

  @override
  String toString() =>
      'Address(id: $addressId, label: $label, fullAddress: $fullAddress, phone: $phoneNumber, isDefault: $isDefault)';
}
