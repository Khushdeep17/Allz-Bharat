import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Address Model Tests', () {
    final testDate = DateTime(2026, 9, 14, 12, 0, 0);

    test('Address instantiation and properties', () {
      final address = Address(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: '123 Main St, Meerut, UP - 250001',
        phoneNumber: '9876543210',
        isDefault: true,
        createdAt: testDate,
      );

      expect(address.addressId, 'addr_1');
      expect(address.label, 'Home');
      expect(address.fullAddress, '123 Main St, Meerut, UP - 250001');
      expect(address.phoneNumber, '9876543210');
      expect(address.isDefault, isTrue);
      expect(address.createdAt, testDate);
    });

    test('Address fromMap with Timestamp', () {
      final map = {
        'addressId': 'addr_1',
        'label': 'Work',
        'fullAddress': 'Tech Park, Sector 62, Noida',
        'phoneNumber': '9876543211',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(testDate),
      };

      final address = Address.fromMap(map, id: 'addr_1');

      expect(address.addressId, 'addr_1');
      expect(address.label, 'Work');
      expect(address.fullAddress, 'Tech Park, Sector 62, Noida');
      expect(address.phoneNumber, '9876543211');
      expect(address.isDefault, isFalse);
      expect(address.createdAt, testDate);
    });

    test('Address fromMap with ISO String', () {
      final map = {
        'label': 'Other',
        'fullAddress': 'Grandma House, Delhi',
        'phoneNumber': '9876543212',
        'isDefault': true,
        'createdAt': testDate.toIso8601String(),
      };

      final address = Address.fromMap(map, id: 'addr_2');

      expect(address.addressId, 'addr_2');
      expect(address.label, 'Other');
      expect(address.fullAddress, 'Grandma House, Delhi');
      expect(address.phoneNumber, '9876543212');
      expect(address.isDefault, isTrue);
      expect(address.createdAt, testDate);
    });

    test('Address toMap serialization', () {
      final address = Address(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: '123 Main St, Meerut',
        phoneNumber: '9876543210',
        isDefault: true,
        createdAt: testDate,
      );

      final map = address.toMap();

      expect(map['label'], 'Home');
      expect(map['fullAddress'], '123 Main St, Meerut');
      expect(map['phoneNumber'], '9876543210');
      expect(map['isDefault'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('Address copyWith', () {
      final address = Address(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: '123 Main St, Meerut',
        phoneNumber: '9876543210',
        isDefault: false,
      );

      final updated = address.copyWith(
        label: 'Office',
        isDefault: true,
      );

      expect(updated.addressId, 'addr_1');
      expect(updated.label, 'Office');
      expect(updated.fullAddress, '123 Main St, Meerut');
      expect(updated.phoneNumber, '9876543210');
      expect(updated.isDefault, isTrue);
    });

    test('Address equality and hashCode', () {
      final a1 = Address(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: '123 Main St',
        phoneNumber: '9876543210',
        isDefault: true,
      );
      final a2 = Address(
        addressId: 'addr_1',
        label: 'Home',
        fullAddress: '123 Main St',
        phoneNumber: '9876543210',
        isDefault: true,
      );
      final a3 = Address(
        addressId: 'addr_2',
        label: 'Home',
        fullAddress: '123 Main St',
        phoneNumber: '9876543210',
        isDefault: true,
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(a3)));
    });
  });
}
