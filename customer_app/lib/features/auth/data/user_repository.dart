import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';
import 'user_repository_impl.dart';

/// Abstract contract for user profile storage operations in Firestore.
abstract class UserRepository {
  /// Checks whether a Firestore user profile document exists at `users/{uid}`.
  Future<bool> checkUserProfileExists(String uid);

  /// Retrieves the user profile document from `users/{uid}` if it exists.
  Future<AppUser?> getUserProfile(String uid);

  /// Creates a new user profile document at `users/{uid}` on first-time signup.
  Future<void> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String name,
  });

  /// Streams real-time updates for a user's profile document.
  Stream<AppUser?> watchUserProfile(String uid);
}

/// Provider for the UserRepository interface.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(FirebaseFirestore.instance);
});

/// Reactive stream provider for the currently authenticated user's Firestore profile.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(null);
  }

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUserProfile(user.uid);
});
