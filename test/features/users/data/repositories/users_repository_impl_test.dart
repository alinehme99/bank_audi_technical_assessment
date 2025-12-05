import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bank_audi_technical_assessment/features/users/data/repositories/users_repository_impl.dart';
import 'package:bank_audi_technical_assessment/features/users/data/datasources/users_remote_data_source.dart';
import 'package:bank_audi_technical_assessment/features/users/data/datasources/users_local_data_source.dart';
import 'package:bank_audi_technical_assessment/features/users/data/models/user_model.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/entities/user.dart';
import 'package:bank_audi_technical_assessment/core/error/exceptions.dart';
import 'package:bank_audi_technical_assessment/core/error/failures.dart';

class MockUsersRemoteDataSource extends Mock implements UsersRemoteDataSource {}
class MockUsersLocalDataSource extends Mock implements UsersLocalDataSource {}

void main() {
  group('UsersRepositoryImpl', () {
    late UsersRepositoryImpl repository;
    late MockUsersRemoteDataSource mockRemoteDataSource;
    late MockUsersLocalDataSource mockLocalDataSource;

    setUp(() {
      mockRemoteDataSource = MockUsersRemoteDataSource();
      mockLocalDataSource = MockUsersLocalDataSource();
      repository = UsersRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
      );
    });

    final testUserModel = UserModel(
      id: 1,
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      avatar: 'https://example.com/avatar.jpg',
    );

    final testUser = User(
      id: 1,
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      avatar: 'https://example.com/avatar.jpg',
    );

    group('getUsers', () {
      test('should return users when remote data source call is successful', () async {
        // Arrange
        when(() => mockRemoteDataSource.getUsers(any(), any()))
            .thenAnswer((_) async => [testUserModel]);

        // Act
        final result = await repository.getUsers(1, 10);

        // Assert
        expect(result, [testUser]);
        verify(() => mockRemoteDataSource.getUsers(1, 10)).called(1);
      });

      test('should throw ServerFailure when ServerException is thrown', () async {
        // Arrange
        when(() => mockRemoteDataSource.getUsers(any(), any()))
            .thenThrow(ServerException('Server error'));

        // Act & Assert
        expect(
          () => repository.getUsers(1, 10),
          throwsA(isA<ServerFailure>()),
        );
      });

      test('should throw NetworkFailure when NetworkException is thrown', () async {
        // Arrange
        when(() => mockRemoteDataSource.getUsers(any(), any()))
            .thenThrow(NetworkException('Network error'));

        // Act & Assert
        expect(
          () => repository.getUsers(1, 10),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('getCachedUsers', () {
      test('should return cached users when local data source call is successful', () async {
        // Arrange
        when(() => mockLocalDataSource.getCachedUsers())
            .thenAnswer((_) async => [testUserModel]);

        // Act
        final result = await repository.getCachedUsers();

        // Assert
        expect(result, [testUser]);
        verify(() => mockLocalDataSource.getCachedUsers()).called(1);
      });

      test('should throw CacheFailure when CacheException is thrown', () async {
        // Arrange
        when(() => mockLocalDataSource.getCachedUsers())
            .thenThrow(CacheException('Cache error'));

        // Act & Assert
        expect(
          () => repository.getCachedUsers(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('cacheUsers', () {
      test('should cache users successfully when local data source call is successful', () async {
        // Arrange
        when(() => mockLocalDataSource.cacheUsers(any()))
            .thenAnswer((_) async {});
        when(() => mockLocalDataSource.cacheTimestamp(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.cacheUsers([testUser], DateTime.now());

        // Assert
        verify(() => mockLocalDataSource.cacheUsers(any())).called(1);
        verify(() => mockLocalDataSource.cacheTimestamp(any())).called(1);
      });

      test('should throw CacheFailure when CacheException is thrown', () async {
        // Arrange
        when(() => mockLocalDataSource.cacheUsers(any()))
            .thenThrow(CacheException('Cache error'));

        // Act & Assert
        expect(
          () => repository.cacheUsers([testUser], DateTime.now()),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('isCacheValid', () {
      test('should return true when cache is valid', () async {
        // Arrange
        final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 15));
        when(() => mockLocalDataSource.getCachedTimestamp())
            .thenAnswer((_) async => recentTimestamp);

        // Act
        final result = await repository.isCacheValid();

        // Assert
        expect(result, true);
      });

      test('should return false when cache is stale', () async {
        // Arrange
        final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 45));
        when(() => mockLocalDataSource.getCachedTimestamp())
            .thenAnswer((_) async => oldTimestamp);

        // Act
        final result = await repository.isCacheValid();

        // Assert
        expect(result, false);
      });

      test('should return false when no timestamp exists', () async {
        // Arrange
        when(() => mockLocalDataSource.getCachedTimestamp())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.isCacheValid();

        // Assert
        expect(result, false);
      });
    });
  });
}
