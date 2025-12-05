import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {"x-api-key": "reqres_798c503ec47e47cdafcdaaa02afa6a88"},
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException('Request timed out. Please try again.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        throw NetworkException('Unable to connect. Please check your Wi-Fi or mobile data connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          if (statusCode >= 500) {
            throw ServerException('Server error. Please try again later.');
          } else if (statusCode == 401) {
            throw UnauthorizedException('Unauthorized access.');
          } else {
            throw ServerException('Request failed with status $statusCode.');
          }
        }
        throw ServerException('An unknown error occurred.');
      default:
        throw ServerException('An unexpected error occurred.');
    }
  }
}
