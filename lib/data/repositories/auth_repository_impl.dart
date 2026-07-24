import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl({
    required Dio dio,
    required SecureStorageService secureStorageService,
  })  : _dio = dio,
        _secureStorageService = secureStorageService;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );

    final apiResponse = response.data;
    final authResponse = AuthResponseModel.fromJson(apiResponse['data']);

    // Save tokens and user data
    await _secureStorageService.saveAccessToken(authResponse.accessToken);
    await _secureStorageService.saveRefreshToken(authResponse.refreshToken);
    
    final authUser = AuthUserModel(
      uid: authResponse.uid,
      userName: authResponse.userName,
      email: authResponse.email,
      role: authResponse.role,
    );
    await _secureStorageService.saveUserJson(
      Map<String, dynamic>.from(authUser.toJson()).toString(),
    );

    return authUser;
  }

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/auth/register',
      data: {
        'userName': username,
        'email': email,
        'password': password,
        'confirmPassword': password,
      },
      options: Options(extra: {'skipAuth': true}),
    );
  }

  @override
  Future<void> logout() async {
    try {
      final token = await _secureStorageService.getAccessToken();
      if (token != null) {
        await _dio.post(
          '/auth/logout',
          data: {},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _secureStorageService.clearAll();
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.patch(
      '/users/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  @override
  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/users/me');
    final apiResponse = response.data;
    return UserProfileModel.fromJson(apiResponse['data']);
  }

  @override
  Future<UserProfile> updateProfile({
    String? userName,
    String? fullName,
    String? dob,
    Gender? gender,
    String? phoneNumber,
    String? address,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (userName != null) data['userName'] = userName;
    if (fullName != null) data['fullName'] = fullName;
    if (dob != null) data['dob'] = dob;
    if (gender != null) data['gender'] = serializeGender(gender);
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (address != null) data['address'] = address;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

    final response = await _dio.patch(
      '/users/me',
      data: data,
    );
    final apiResponse = response.data;
    return UserProfileModel.fromJson(apiResponse['data']);
  }

  @override
  Future<AuthUser> googleAuth({required String token}) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'idToken': token},
      options: Options(extra: {'skipAuth': true}),
    );

    final apiResponse = response.data;
    final authResponse = AuthResponseModel.fromJson(apiResponse['data']);

    // Save tokens and user data
    await _secureStorageService.saveAccessToken(authResponse.accessToken);
    await _secureStorageService.saveRefreshToken(authResponse.refreshToken);
    
    final authUser = AuthUserModel(
      uid: authResponse.uid,
      userName: authResponse.userName,
      email: authResponse.email,
      role: authResponse.role,
    );
    return authUser;
  }
}
