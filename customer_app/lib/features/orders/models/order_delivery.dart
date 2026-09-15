import '../../addresses/models/address.dart';

/// Immutable snapshot of delivery address details at the time of order placement.
class OrderDelivery {
  final String addressId;
  final String label;
  final String fullAddress;
  final String phoneNumber;

  const OrderDelivery({
    required this.addressId,
    required this.label,
    required this.fullAddress,
    required this.phoneNumber,
  });

  factory OrderDelivery.fromAddress(Address address) {
    return OrderDelivery(
      addressId: address.addressId,
      label: address.label,
      fullAddress: address.fullAddress,
      phoneNumber: address.phoneNumber,
    );
  }

  factory OrderDelivery.fromMap(Map<String, dynamic> map) {
    return OrderDelivery(
      addressId: (map['addressId'] ?? map['id'] ?? '') as String,
      label: (map['label'] ?? '') as String,
      fullAddress: (map['fullAddress'] ?? map['address'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? map['phone'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'label': label,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderDelivery &&
        other.addressId == addressId &&
        other.label == label &&
        other.fullAddress == fullAddress &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode =>
      addressId.hashCode ^
      label.hashCode ^
      fullAddress.hashCode ^
      phoneNumber.hashCode;
}
