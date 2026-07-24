enum UserRole { customer, contentAdmin, systemAdmin }

enum Gender { male, female, other }

class AuthUser {
  final String uid;
  final String userName;
  final String email;
  final UserRole role;

  const AuthUser({
    required this.uid,
    required this.userName,
    required this.email,
    required this.role,
  });
}

class UserProfile {
  final String id;
  final String userName;
  final String email;
  final String? fullName;
  final String? dob;
  final Gender? gender;
  final String? phoneNumber;
  final String? address;
  final String? avatarUrl;
  final UserRole role;
  final int token;
  final String? tierId;
  final String? lastActiveDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userName,
    required this.email,
    this.fullName,
    this.dob,
    this.gender,
    this.phoneNumber,
    this.address,
    this.avatarUrl,
    required this.role,
    required this.token,
    this.tierId,
    this.lastActiveDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
