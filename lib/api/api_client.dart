import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal();

  static const storage = FlutterSecureStorage();
  static const _baseUrlKey = 'api_base_url';
  static String baseUrl = 'https://api.coka.ai';

  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  late Dio dio;
  void Function()? onUnauthorized;

  /// Khởi tạo Dio và interceptor
  Future<void> init({String? customBaseUrl}) async {
    final urlToUse = customBaseUrl ?? await getBaseUrl();

    dio = Dio(BaseOptions(
      baseUrl: urlToUse,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _requestInterceptor,
        onResponse: (res, handler) => handler.next(res),
        onError: _errorInterceptor,
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(onError: _retryInterceptor),
    );

    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 120,
      ));
    }
  }

  /// Lấy baseUrl hiện tại từ SharedPreferences
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? baseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    await init(); // Reinitialize Dio with the new base URL
  }

  // ================== Interceptors ==================

  Future<void> _requestInterceptor(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['retryCount'] ??= 0;

    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  Future<void> _errorInterceptor(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('[API ERROR] ${err.requestOptions.path} - ${err.response?.statusCode}');
    print('Error response: ${err.response?.data}');

    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          final newToken = await storage.read(key: 'access_token');
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final retryResponse = await dio.request(
            options.path,
            options: Options(
              method: options.method,
              headers: options.headers,
            ),
            data: options.data,
            queryParameters: options.queryParameters,
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          print('Retry after refresh failed: $e');
        }
      } else {
        await storage.deleteAll();
        onUnauthorized?.call();
      }
    }

    return handler.next(err);
  }

  Future<void> _retryInterceptor(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    int retryCount = options.extra['retryCount'] ?? 0;

    final shouldRetry = _shouldRetry(err) && retryCount < maxRetries;

    if (shouldRetry) {
      print('Retrying request (${retryCount + 1}/$maxRetries): ${options.path}');
      options.extra['retryCount'] = retryCount + 1;

      await Future.delayed(Duration(milliseconds: retryDelayMs * (retryCount + 1)));

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500 &&
            err.response!.statusCode! < 600);
  }

  /// Refresh token API
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await dio.post('/api/v1/account/refreshtoken', data: {
        'refreshToken': refreshToken,
      });

      final content = response.data['content'];
      if (content == null || content['accessToken'] == null) return false;

      await storage.write(key: 'access_token', value: content['accessToken']);
      await storage.write(key: 'refresh_token', value: content['refreshToken']);
      print('🔄 Token refreshed successfully');
      return true;
    } catch (e) {
      print('🔁 Failed to refresh token: $e');
      return false;
    }
  }

  // ============ Convenience Methods =============

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await dio.delete(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }
}
