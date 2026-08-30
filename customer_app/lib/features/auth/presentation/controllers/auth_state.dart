enum AuthStatus {
  initial,
  sendingOtp,
  codeSent,
  verifyingOtp,
  authenticated,
  error,
}

/// State representation for authentication flow.
class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
  });

  bool get isLoading =>
      status == AuthStatus.sendingOtp || status == AuthStatus.verifyingOtp;

  bool get isCodeSent => status == AuthStatus.codeSent;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, phone: $phoneNumber, verificationId: $verificationId, error: $errorMessage)';
}
