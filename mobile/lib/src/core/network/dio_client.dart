import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class DioClient {
  DioClient({TokenProvider? tokenProvider})
      : _tokenProvider = tokenProvider,
        _dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final TokenProvider? _tokenProvider;

  Dio get client => _dio;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final response = error.response;
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        response: response,
        error: ApiException(
          message: _extractMessage(error),
          statusCode: response?.statusCode,
          data: response?.data,
        ),
        type: error.type,
      ),
    );
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return error.message ?? 'Unexpected API error';
  }
}
