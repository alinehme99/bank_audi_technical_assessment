import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers(int page, int perPage);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final DioClient _dioClient;

  UsersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<UserModel>> getUsers(int page, int perPage) async {
    try {
      final response = await _dioClient.get(
        '/users',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      if (data['data'] == null) {
        throw ServerException('Invalid response format');
      }

      final List<dynamic> usersJson = data['data'];
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } on ServerException catch (e) {
      // Re-throw ServerException as-is
      rethrow;
    } on NetworkException catch (e) {
      // Re-throw NetworkException as-is
      rethrow;
    } on TimeoutException catch (e) {
      // Re-throw TimeoutException as-is
      rethrow;
    } on DioException catch (e) {
      // Only catch actual DioExceptions that weren't already converted
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
