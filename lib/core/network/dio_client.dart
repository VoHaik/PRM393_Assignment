import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../constants/env_config.dart';
import '../../data/datasources/local/secure_storage_service.dart';

class DioClient {
  late final Dio dio;
  final SecureStorageService _secureStorageService;

  static String get defaultBaseUrl => EnvConfig.defaultApiUrl;

  DioClient({
    required SecureStorageService secureStorageService,
    String? baseUrl,
  }) : _secureStorageService = secureStorageService {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await _secureStorageService.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check if response is 401 Unauthorized and skipAuth is not true
          final skipAuth = error.requestOptions.extra['skipAuth'] == true;
          if (error.response?.statusCode == 401 && !skipAuth) {
            final refreshToken = await _secureStorageService.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Synchronously attempt to refresh the token using a separate Dio instance to avoid recursive intercepts
                final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
                final response = await refreshDio.post(
                  '/auth/refresh', // Adjusted based on standard refresh endpoint paths
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = response.data['data'];
                  final newAccessToken = data['accessToken'] as String;
                  final newRefreshToken = data['refreshToken'] as String?;

                  await _secureStorageService.saveAccessToken(newAccessToken);
                  if (newRefreshToken != null) {
                    await _secureStorageService.saveRefreshToken(newRefreshToken);
                  }

                  // Clone and retry the original request with the new token
                  final requestOptions = error.requestOptions;
                  requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                  final retryResponse = await dio.fetch(requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                // Refresh failed: clear storage and forward error
                await _secureStorageService.clearAll();
                // Optionally emit a logout event to the App's AuthBloc
              }
            } else {
              await _secureStorageService.clearAll();
            }
          }
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }
  }
}
