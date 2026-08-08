import 'api_error_code.dart';

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.requestId,
    this.statusCode,
  });

  final ApiErrorCode code;
  final String message;
  final String? requestId;
  final int? statusCode;

  factory ApiException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiException(
      code: _mapCode(json['code'] as String?),
      message: (json['message'] as String?) ?? '请求失败',
      requestId: json['request_id'] as String?,
      statusCode: statusCode,
    );
  }

  static ApiErrorCode _mapCode(String? code) {
    switch (code) {
      case 'auth_invalid':
        return ApiErrorCode.authInvalid;
      case 'rate_limited':
        return ApiErrorCode.rateLimited;
      case 'engine_timeout':
        return ApiErrorCode.engineTimeout;
      case 'engine_unavailable':
        return ApiErrorCode.engineUnavailable;
      case 'asr_failed':
        return ApiErrorCode.asrFailed;
      case 'validation_error':
        return ApiErrorCode.validationError;
      case 'internal_error':
        return ApiErrorCode.internalError;
      default:
        return ApiErrorCode.unknown;
    }
  }

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
