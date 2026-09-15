import 'package:customer_app/features/addresses/data/address_repository.dart';
import 'package:customer_app/features/addresses/models/address.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAddressRepository implements AddressRepository {
  final Map<String, List<Address>> _store = {};

  FakeAddressRepository([Map<String, List<Address>>? initialData]) {
    if (initialData != null) {
      _store.addAll(initialData.map((k, v) => MapEntry(k, List<Address>.from(v))));
    }
  }

  @override
  Future<List<Address>> getAddresses(String uid) async {
    final list = List<Address>.from(_store[uid] ?? []);
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    return list;
  }

  @override
  Stream<List<Address>> watchAddresses(String uid) {
    return Stream.value(_store[uid] ?? []);
  }

  @override
  Future<String> addAddress(String uid, Address address) async {
    final current = List<Address>.from(_store[uid] ?? []);
    final newId = 'addr_${DateTime.now().millisecondsSinceEpoch}_${current.length}';

    var isDefault = address.isDefault;
    if (current.isEmpty) {
      isDefault = true;
    }

    if (isDefault) {
      for (var i = 0; i < current.length; i++) {
        current[i] = current[i].copyWith(isDefault: false);
      }
    }

    final toAdd = address.copyWith(
      addressId: newId,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
    current.add(toAdd);
    _store[uid] = current;
    return newId;
  }

  @override
  Future<void> updateAddress(String uid, String addressId, Address address) async {
    final current = List<Address>.from(_store[uid] ?? []);
    final index = current.indexWhere((a) => a.addressId == addressId);
    if (index == -1) return;

    if (address.isDefault) {
      for (var i = 0; i < current.length; i++) {
        if (current[i].addressId != addressId) {
          current[i] = current[i].copyWith(isDefault: false);
        }
      }
    }

    current[index] = address.copyWith(addressId: addressId);
    _store[uid] = current;
  }

  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    final current = List<Address>.from(_store[uid] ?? []);
    for (var i = 0; i < current.length; i++) {
      current[i] = current[i].copyWith(
        isDefault: current[i].addressId == addressId,
      );
    }
    _store[uid] = current;
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    final current = List<Address>.from(_store[uid] ?? []);
    current.removeWhere((a) => a.addressId == addressId);
    _store[uid] = current;
  }
}

void main() {
  group('AddressRepository & Default Batch Behavior Tests', () {
    const testUid = 'user_123';

    test('getAddresses returns empty list initially', () async {
      final repo = FakeAddressRepository();
      final addresses = await repo.getAddresses(testUid);
      expect(addresses, isEmpty);
    });

    test('Adding first address automatically sets isDefault=true', () async {
      final repo = FakeAddressRepository();
      const newAddr = Address(
        addressId: '',
        label: 'Home',
        fullAddress: '123 Main St, Meerut',
        phoneNumber: '9876543210',
        isDefault: false,
      );

      final id = await repo.addAddress(testUid, newAddr);
      expect(id, isNotEmpty);

      final addresses = await repo.getAddresses(testUid);
      expect(addresses.length, 1);
      expect(addresses.first.isDefault, isTrue);
      expect(addresses.first.label, 'Home');
    });

    test('Adding second address with isDefault=true unsets previous default', () async {
      final repo = FakeAddressRepository();
      await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Home',
          fullAddress: '123 Main St, Meerut',
          phoneNumber: '9876543210',
          isDefault: true,
        ),
      );

      await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Work',
          fullAddress: 'Tech Hub, Noida',
          phoneNumber: '9876543211',
          isDefault: true,
        ),
      );

      final addresses = await repo.getAddresses(testUid);
      expect(addresses.length, 2);

      final work = addresses.firstWhere((a) => a.label == 'Work');
      final home = addresses.firstWhere((a) => a.label == 'Home');

      expect(work.isDefault, isTrue);
      expect(home.isDefault, isFalse);
    });

    test('setDefaultAddress sets selected address as default and unsets others', () async {
      final repo = FakeAddressRepository();
      final id1 = await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Home',
          fullAddress: '123 Main St, Meerut',
          phoneNumber: '9876543210',
          isDefault: true,
        ),
      );

      final id2 = await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Work',
          fullAddress: 'Tech Hub, Noida',
          phoneNumber: '9876543211',
          isDefault: false,
        ),
      );

      await repo.setDefaultAddress(testUid, id2);

      final addresses = await repo.getAddresses(testUid);
      final work = addresses.firstWhere((a) => a.addressId == id2);
      final home = addresses.firstWhere((a) => a.addressId == id1);

      expect(work.isDefault, isTrue);
      expect(home.isDefault, isFalse);
    });

    test('updateAddress updates fields and handles default switch cleanly', () async {
      final repo = FakeAddressRepository();
      final id1 = await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Home',
          fullAddress: '123 Main St',
          phoneNumber: '9876543210',
          isDefault: true,
        ),
      );

      final id2 = await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Work',
          fullAddress: 'Old Address',
          phoneNumber: '9876543211',
          isDefault: false,
        ),
      );

      await repo.updateAddress(
        testUid,
        id2,
        const Address(
          addressId: 'temp',
          label: 'Work HQ',
          fullAddress: 'New Address, Floor 5',
          phoneNumber: '9999999999',
          isDefault: true,
        ),
      );

      final addresses = await repo.getAddresses(testUid);
      final work = addresses.firstWhere((a) => a.addressId == id2);
      final home = addresses.firstWhere((a) => a.addressId == id1);

      expect(work.label, 'Work HQ');
      expect(work.fullAddress, 'New Address, Floor 5');
      expect(work.phoneNumber, '9999999999');
      expect(work.isDefault, isTrue);
      expect(home.isDefault, isFalse);
    });

    test('deleteAddress removes the document', () async {
      final repo = FakeAddressRepository();
      final id1 = await repo.addAddress(
        testUid,
        const Address(
          addressId: '',
          label: 'Home',
          fullAddress: '123 Main St',
          phoneNumber: '9876543210',
        ),
      );

      var addresses = await repo.getAddresses(testUid);
      expect(addresses.length, 1);

      await repo.deleteAddress(testUid, id1);

      addresses = await repo.getAddresses(testUid);
      expect(addresses, isEmpty);
    });
  });
}
