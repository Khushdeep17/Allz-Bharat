import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Represents a customer user entity in Allz Bharat.
class AppUser {
  final String uid;
  final String? phoneNumber;
  final String? displayName;
  final String? email;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    this.phoneNumber,
    this.displayName,
    this.email,
    this.createdAt,
  });

  factory AppUser.fromFirebaseUser(fb.User user) {
    return AppUser(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      email: user.email,
      createdAt: user.metadata.creationTime,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? phoneNumber,
    String? displayName,
    String? email,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.displayName == displayName &&
        other.email == email;
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      phoneNumber.hashCode ^
      displayName.hashCode ^
      email.hashCode;
}
