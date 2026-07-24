import '../../domain/entities/user.dart';

UserRole parseUserRole(String? roleStr) {
  switch (roleStr?.toUpperCase()) {
    case 'CONTENT_ADMIN':
      return UserRole.contentAdmin;
    case 'SYSTEM_ADMIN':
      return UserRole.systemAdmin;
    case 'CUSTOMER':
    default:
      return UserRole.customer;
  }
}

String serializeUserRole(UserRole role) {
  switch (role) {
    case UserRole.contentAdmin:
      return 'CONTENT_ADMIN';
    case UserRole.systemAdmin:
      return 'SYSTEM_ADMIN';
    case UserRole.customer:
      return 'CUSTOMER';
  }
}

Gender? parseGender(String? genderStr) {
  switch (genderStr?.toUpperCase()) {
    case 'MALE':
      return Gender.male;
    case 'FEMALE':
      return Gender.female;
    case 'OTHER':
      return Gender.other;
    default:
      return null;
  }
}

String? serializeGender(Gender? gender) {
  if (gender == null) return null;
  switch (gender) {
    case Gender.male:
      return 'MALE';
    case Gender.female:
      return 'FEMALE';
    case Gender.other:
      return 'OTHER';
  }
}

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.userName,
    required super.email,
    required super.role,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      uid: (json['uid'] ?? json['_id'] ?? '') as String,
      userName: json['userName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: parseUserRole(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'role': serializeUserRole(role),
    };
  }
}

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.userName,
    required super.email,
    super.fullName,
    super.dob,
    super.gender,
    super.phoneNumber,
    super.address,
    super.avatarUrl,
    required super.role,
    required super.token,
    super.tierId,
    super.lastActiveDate,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: (json['uid'] ?? json['_id'] ?? '') as String,
      userName: json['userName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      dob: json['dob'] as String?,
      gender: parseGender(json['gender'] as String?),
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: parseUserRole(json['role'] as String?),
      token: json['token'] as int? ?? 0,
      tierId: json['tierId'] as String?,
      lastActiveDate: json['lastActiveDate'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userName': userName,
      'email': email,
      'fullName': fullName,
      'dob': dob,
      'gender': serializeGender(gender),
      'phoneNumber': phoneNumber,
      'address': address,
      'avatarUrl': avatarUrl,
      'role': serializeUserRole(role),
      'token': token,
      'tierId': tierId,
      'lastActiveDate': lastActiveDate,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AuthResponseModel {
  final String uid;
  final String userName;
  final String email;
  final UserRole role;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthResponseModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      uid: (json['uid'] ?? json['_id'] ?? '') as String,
      userName: json['userName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: parseUserRole(json['role'] as String?),
      accessToken: (json['accessToken'] ?? json['token'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 3600,
    );
  }
}
