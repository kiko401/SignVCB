import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_provider.dart';
import '../storage/token_storage.dart';
import '../utils/uuid_generator.dart';
import 'api_error_code.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'http://127.0.0.1:8081',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['X-Request-ID'] = UuidGenerator.v4();
        final isPublic = options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/app_config');
        if (!isPublic) {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (statusCode == 401) {
          await ref.read(authProvider.notifier).forceLogout();
        }
        if (data is Map<String, dynamic>) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException.fromJson(data, statusCode: statusCode),
              response: error.response,
              type: error.type,
            ),
          );
          return;
        }
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: ApiException(
              code: statusCode == 401 ? ApiErrorCode.authInvalid : ApiErrorCode.unknown,
              message: error.message ?? '网络请求失败',
              statusCode: statusCode,
            ),
            response: error.response,
            type: error.type,
          ),
        );
      },
    ),
  );

  return dio;
});
