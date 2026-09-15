import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../models/address.dart';
import 'address_repository_impl.dart';

/// Abstract contract for user delivery address operations in Firestore.
abstract class AddressRepository {
  /// Retrieves all saved addresses for the user at `users/{uid}/addresses`.
  Future<List<Address>> getAddresses(String uid);

  /// Streams real-time updates for a user's delivery addresses.
  Stream<List<Address>> watchAddresses(String uid);

  /// Adds a new address under `users/{uid}/addresses`.
  /// If `address.isDefault` is true, automatically unsets any existing default addresses via WriteBatch.
  Future<String> addAddress(String uid, Address address);

  /// Updates an existing address document.
  /// If `address.isDefault` is true, unsets all other default addresses in the same batch.
  Future<void> updateAddress(String uid, String addressId, Address address);

  /// Deletes the specified address from `users/{uid}/addresses/{addressId}`.
  Future<void> deleteAddress(String uid, String addressId);

  /// Sets the specified address as default and unsets all others for that user via WriteBatch.
  Future<void> setDefaultAddress(String uid, String addressId);
}

/// Provider for the AddressRepository interface.
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return FirestoreAddressRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for the currently authenticated user's address list.
final userAddressesStreamProvider = StreamProvider<List<Address>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(const <Address>[]);
  }

  final addressRepo = ref.watch(addressRepositoryProvider);
  return addressRepo.watchAddresses(user.uid);
});

/// Convenience provider returning the currently authenticated user's default delivery address if one exists.
final defaultAddressProvider = Provider<Address?>((ref) {
  final addressesAsync = ref.watch(userAddressesStreamProvider);
  return addressesAsync.maybeWhen(
    data: (addresses) {
      try {
        return addresses.firstWhere((a) => a.isDefault);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});
