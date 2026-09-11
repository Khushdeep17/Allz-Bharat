import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'user_repository.dart';

/// Firestore implementation of [UserRepository].
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<bool> checkUserProfileExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[FirestoreUserRepository] checkUserProfileExists error: $e');
      return false;
    }
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppUser.fromMap({
        ...doc.data()!,
        'uid': uid,
      });
    } catch (e) {
      debugPrint('[FirestoreUserRepository] getUserProfile error: $e');
      return null;
    }
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String name,
  }) async {
    final cleanName = name.trim();
    final data = <String, dynamic>{
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': cleanName,
      'displayName': cleanName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    debugPrint('[FirestoreUserRepository] Creating user profile at users/$uid with data: $data');

    await _usersCollection.doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map<AppUser?>((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return AppUser.fromMap({
            ...snapshot.data()!,
            'uid': uid,
          });
        })
        .handleError((error) {
          debugPrint('[FirestoreUserRepository] watchUserProfile error: $error');
          return null;
        });
  }
}
