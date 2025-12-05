import '../../domain/entities/user.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';
import '../datasources/users_local_data_source.dart';
import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/hive_constants.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;
  final UsersLocalDataSource localDataSource;

  UsersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<User>> getUsers(int page, int perPage) async {
    try {
      final userModels = await remoteDataSource.getUsers(page, perPage);
      return userModels.map((model) => model.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on TimeoutException catch (e) {
      throw TimeoutFailure(e.message);
    } catch (e) {
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('connection') ||
          e.toString().contains('internet') ||
          e.toString().contains('SocketException')) {
        throw NetworkFailure('Please check your internet connection and try again.');
      }
      throw ServerFailure('Unexpected error: Please try again.');
    }
  }

  @override
  Future<List<User>> getCachedUsers() async {
    try {
      final userModels = await localDataSource.getCachedUsers();
      return userModels.map((model) => model.toEntity()).toList();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    } catch (e) {
      // Don't throw network errors from cache operations - return empty list instead
      return [];
    }
  }

  @override
  Future<void> cacheUsers(List<User> users, DateTime timestamp) async {
    try {
      final userModels = users.map((user) => user.toModel()).toList();
      await localDataSource.cacheUsers(userModels);
      await localDataSource.cacheTimestamp(timestamp);
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    } catch (e) {
      throw CacheFailure('Failed to cache users: $e');
    }
  }

  @override
  Future<DateTime?> getCachedTimestamp() async {
    try {
      return await localDataSource.getCachedTimestamp();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    } catch (e) {
      throw CacheFailure('Failed to get cached timestamp: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final timestamp = await getCachedTimestamp();
      if (timestamp == null) return false;
      
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      return difference <= HiveConstants.cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }
}

extension UserModelExtension on UserModel {
  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }
}

extension UserExtension on User {
  UserModel toModel() {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }
}
