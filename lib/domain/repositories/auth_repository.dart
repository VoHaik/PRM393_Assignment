import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<UserProfile> getProfile();

  Future<UserProfile> updateProfile({
    String? userName,
    String? fullName,
    String? dob,
    Gender? gender,
    String? phoneNumber,
    String? address,
    String? avatarUrl,
  });

  Future<AuthUser> googleAuth({required String token});
}
