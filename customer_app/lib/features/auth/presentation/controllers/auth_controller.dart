import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import 'auth_state.dart';

/// Riverpod StateNotifier for managing auth operations and UI state.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState());

  /// Triggers sending an OTP to the given 10-digit Indian phone number.
  Future<void> sendOtp(String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
        ? '+$cleanPhone'
        : '+91$cleanPhone';

    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phoneNumber: formattedPhone,
      errorMessage: null,
    );

    try {
      await _authRepository.sendOtp(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: resendToken,
            errorMessage: null,
          );
        },
        onVerificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: _mapFirebaseError(e),
          );
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (instant verification on Android)
          if (credential.smsCode != null && state.verificationId != null) {
            await verifyOtp(credential.smsCode!);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Resends OTP using the stored resendToken if available.
  Future<void> resendOtp() async {
    final phone = state.phoneNumber;
    if (phone == null || phone.isEmpty) return;

    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      errorMessage: null,
    );

    try {
      await _authRepository.sendOtp(
        phoneNumber: phone,
        forceResendingToken: state.resendToken,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: resendToken,
            errorMessage: null,
          );
        },
        onVerificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: _mapFirebaseError(e),
          );
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          if (credential.smsCode != null && state.verificationId != null) {
            await verifyOtp(credential.smsCode!);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Verifies the entered 6-digit SMS OTP code.
  Future<bool> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification session expired. Please request a new OTP.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.verifyingOtp,
      errorMessage: null,
    );

    try {
      await _authRepository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP. Please check and try again.',
      );
      return false;
    }
  }

  /// Signs the user out.
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState();
  }

  /// Clears error message.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Resets controller state.
  void reset() {
    state = const AuthState();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'timeout':
        return e.message ?? 'Request timed out after 15 seconds. Please try again.';
      case 'web-auth-error':
        return 'Web authentication error: ${e.message}';
      case 'invalid-phone-number':
        return 'The phone number entered is invalid. Please enter a valid 10-digit number.';
      case 'invalid-verification-code':
        return 'The entered OTP code is incorrect. Please try again.';
      case 'session-expired':
        return 'The OTP has expired. Please tap Resend to get a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment before trying again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for today. Please try again later or use test credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Riverpod provider for AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});
