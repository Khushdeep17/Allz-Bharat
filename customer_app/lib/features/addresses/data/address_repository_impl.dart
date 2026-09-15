import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/address.dart';
import 'address_repository.dart';

/// Firestore implementation of [AddressRepository].
/// Operates exclusively within the `users/{uid}/addresses` subcollection.
class FirestoreAddressRepository implements AddressRepository {
  final FirebaseFirestore _firestore;

  FirestoreAddressRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _addressesCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('addresses');

  @override
  Future<List<Address>> getAddresses(String uid) async {
    try {
      final snapshot = await _addressesCollection(uid).get();
      final list = snapshot.docs
          .map((doc) => Address.fromFirestore(doc))
          .toList();

      // Sort: default address first, then newer createdAt first
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return 0;
      });

      return list;
    } catch (e) {
      debugPrint('[FirestoreAddressRepository] getAddresses error for user $uid: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Address>> watchAddresses(String uid) {
    return _addressesCollection(uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Address.fromFirestore(doc))
              .toList();

          list.sort((a, b) {
            if (a.isDefault && !b.isDefault) return -1;
            if (!a.isDefault && b.isDefault) return 1;
            if (a.createdAt != null && b.createdAt != null) {
              return b.createdAt!.compareTo(a.createdAt!);
            }
            return 0;
          });

          return list;
        })
        .handleError((error) {
          debugPrint('[FirestoreAddressRepository] watchAddresses error for user $uid: $error');
          throw error;
        });
  }

  @override
  Future<String> addAddress(String uid, Address address) async {
    try {
      final colRef = _addressesCollection(uid);

      if (address.isDefault) {
        // Enforce single default: batch unset all other defaults and insert new address
        final snapshot = await colRef.get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          if (doc.data()['isDefault'] == true) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }

        final newDocRef = colRef.doc();
        batch.set(newDocRef, address.toMap());
        await batch.commit();
        return newDocRef.id;
      } else {
        // Check if this is the user's very first address; if so, make it default automatically
        final snapshot = await colRef.limit(1).get();
        if (snapshot.docs.isEmpty) {
          final docRef = await colRef.add(
            address.copyWith(isDefault: true).toMap(),
          );
          return docRef.id;
        }

        final docRef = await colRef.add(address.toMap());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('[FirestoreAddressRepository] addAddress error for user $uid: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAddress(
    String uid,
    String addressId,
    Address address,
  ) async {
    try {
      final colRef = _addressesCollection(uid);

      if (address.isDefault) {
        final snapshot = await colRef.get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          if (doc.id != addressId && doc.data()['isDefault'] == true) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }

        batch.set(
          colRef.doc(addressId),
          address.toMap(),
          SetOptions(merge: true),
        );
        await batch.commit();
      } else {
        await colRef.doc(addressId).set(
              address.toMap(),
              SetOptions(merge: true),
            );
      }
    } catch (e) {
      debugPrint('[FirestoreAddressRepository] updateAddress error for user $uid, address $addressId: $e');
      rethrow;
    }
  }

  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    try {
      final colRef = _addressesCollection(uid);
      final snapshot = await colRef.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        if (doc.id == addressId) {
          batch.update(doc.reference, {'isDefault': true});
        } else if (doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreAddressRepository] setDefaultAddress error for user $uid, address $addressId: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    try {
      await _addressesCollection(uid).doc(addressId).delete();
    } catch (e) {
      debugPrint('[FirestoreAddressRepository] deleteAddress error for user $uid, address $addressId: $e');
      rethrow;
    }
  }
}
