import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/web_recaptcha_helper.dart';
import 'auth_repository.dart';

/// Firebase implementation of the AuthRepository supporting Android & Web.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _webRecaptchaVerifier;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    debugPrint('[AuthRepository] Sending OTP to: "$phoneNumber" (kIsWeb: $kIsWeb)');

    if (kIsWeb) {
      try {
        // Clear previous verifier and ensure container is reset
        try {
          _webRecaptchaVerifier?.clear();
        } catch (e) {
          debugPrint('[AuthRepository] Clearing previous verifier: $e');
        }
        _webRecaptchaVerifier = null;
        hideRecaptcha();

        // Make container available for reCAPTCHA
        showRecaptcha();

        // Create a fresh RecaptchaVerifier instance for this attempt
        final verifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.compact,
          theme: RecaptchaVerifierTheme.light,
          onSuccess: () {
            debugPrint('[AuthRepository] reCAPTCHA passed successfully');
            hideRecaptcha();
          },
          onError: (error) {
            debugPrint('[AuthRepository] reCAPTCHA error: $error');
            hideRecaptcha();
          },
          onExpired: () {
            debugPrint('[AuthRepository] reCAPTCHA expired, please re-click');
          },
        );
        _webRecaptchaVerifier = verifier;

        debugPrint('[AuthRepository] Calling signInWithPhoneNumber (60s timeout)...');

        final confirmationResult = await _firebaseAuth
            .signInWithPhoneNumber(
              phoneNumber,
              verifier,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                hideRecaptcha();
                throw FirebaseAuthException(
                  code: 'timeout',
                  message:
                      'OTP request timed out after 60s. Please solve the reCAPTCHA challenge if prompted.',
                );
              },
            );

        _webConfirmationResult = confirmationResult;
        debugPrint(
          '[AuthRepository] Web code sent successfully! verificationId: ${confirmationResult.verificationId}',
        );
        hideRecaptcha();
        onCodeSent(confirmationResult.verificationId, null);
      } on FirebaseAuthException catch (e) {
        hideRecaptcha();
        debugPrint('[AuthRepository] Web phone auth failed: ${e.code} - ${e.message}');
        onVerificationFailed(e);
      } catch (e) {
        hideRecaptcha();
        debugPrint('[AuthRepository] Web phone auth unknown error: $e');
        onVerificationFailed(
          FirebaseAuthException(
            code: 'web-auth-error',
            message: e.toString(),
          ),
        );
      }
    } else {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken,
      );
    }
  }

  @override
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    debugPrint('[AuthRepository] Verifying OTP: "$smsCode" for verificationId: "$verificationId" (kIsWeb: $kIsWeb)');

    if (kIsWeb && _webConfirmationResult != null) {
      final credential = await _webConfirmationResult!.confirm(smsCode);
      debugPrint('[AuthRepository] Web OTP confirmed successfully. uid: ${credential.user?.uid}');
      try {
        _webRecaptchaVerifier?.clear();
      } catch (_) {}
      _webRecaptchaVerifier = null;
      hideRecaptcha();
      return credential;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    debugPrint('[AuthRepository] Mobile OTP confirmed successfully. uid: ${userCredential.user?.uid}');
    return userCredential;
  }

  @override
  Future<void> signOut() async {
    try {
      _webRecaptchaVerifier?.clear();
    } catch (_) {}
    _webRecaptchaVerifier = null;
    _webConfirmationResult = null;
    hideRecaptcha();
    await _firebaseAuth.signOut();
  }
}
