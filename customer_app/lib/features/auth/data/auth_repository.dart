import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository_impl.dart';

/// Abstract interface for authentication operations.
abstract class AuthRepository {
  /// Stream of Firebase user auth state changes.
  Stream<User?> get authStateChanges;

  /// Current authenticated Firebase user.
  User? get currentUser;

  /// Sends an SMS OTP to the provided phone number (+91...).
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  /// Verifies the entered SMS code against the verificationId.
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Signs the user out of Firebase.
  Future<void> signOut();
}

/// Provider for the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
});

/// Stream provider for auth state changes.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
