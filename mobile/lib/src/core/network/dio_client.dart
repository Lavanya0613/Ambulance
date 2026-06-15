import 'package:dio/dio.dart';

import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class DioClient {
  DioClient({
    String baseUrl = 'https://api.example.com/v1',
    TokenProvider? tokenProvider,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  })  : _tokenProvider = tokenProvider,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            responseType: ResponseType.json,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
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

  Response<dynamic> _onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    handler.next(response);
    return response;
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
