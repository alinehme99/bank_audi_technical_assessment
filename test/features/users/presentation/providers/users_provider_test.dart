import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bank_audi_technical_assessment/features/users/presentation/providers/users_provider.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/repositories/users_repository.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/entities/user.dart';
import 'package:bank_audi_technical_assessment/core/error/failures.dart';

class MockUsersRepository extends Mock implements UsersRepository {}

void main() {
  group('UsersProvider', () {
    late UsersProvider provider;
    late MockUsersRepository mockRepository;

    setUp(() {
      mockRepository = MockUsersRepository();
      provider = UsersProvider(mockRepository);
    });

    final testUsers = [
      User(
        id: 1,
        email: 'john@example.com',
        firstName: 'John',
        lastName: 'Doe',
        avatar: 'https://example.com/avatar1.jpg',
      ),
      User(
        id: 2,
        email: 'jane@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: 'https://example.com/avatar2.jpg',
      ),
    ];

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(provider.visibleUsers, isEmpty);
        expect(provider.isInitialLoading, false);
        expect(provider.isLoadingMore, false);
        expect(provider.isRefreshing, false);
        expect(provider.hasMore, true);
        expect(provider.searchQuery, isEmpty);
        expect(provider.errorMessage, null);
        expect(provider.isOffline, false);
        expect(provider.hasError, false);
        expect(provider.isEmpty, true);
      });
    });

    group('loadInitialUsers', () {
      test('should load users from cache and API when cache is valid', () async {
        // Arrange
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => true);

        // Act
        await provider.loadInitialUsers();

        // Assert
        expect(provider.visibleUsers, testUsers);
        expect(provider.isInitialLoading, false);
        expect(provider.hasError, false);
        verify(() => mockRepository.getCachedUsers()).called(1);
        verify(() => mockRepository.isCacheValid()).called(1);
        verifyNever(() => mockRepository.getUsers(any(), any()));
      });

      test('should load users from API when cache is empty', () async {
        // Arrange
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => []);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => false);
        when(() => mockRepository.getUsers(1, 10))
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await provider.loadInitialUsers();

        // Assert
        expect(provider.visibleUsers, testUsers);
        expect(provider.isInitialLoading, false);
        expect(provider.hasError, false);
        verify(() => mockRepository.getCachedUsers()).called(1);
        verify(() => mockRepository.getUsers(1, 10)).called(1);
        verify(() => mockRepository.cacheUsers(testUsers, any())).called(1);
      });

      test('should set error state when repository throws exception', () async {
        // Arrange
        when(() => mockRepository.getCachedUsers())
            .thenThrow(NetworkFailure('No internet'));

        // Act
        await provider.loadInitialUsers();

        // Assert
        expect(provider.visibleUsers, isEmpty);
        expect(provider.isInitialLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'Please check your internet connection and try again.');
        expect(provider.isOffline, true);
      });
    });

    group('loadMoreUsers', () {
      setUp(() async {
        // Setup initial users first - use full page to enable pagination
        final initialUsers = List.generate(10, (index) => User(
          id: index + 1,
          email: 'user${index + 1}@example.com',
          firstName: 'User${index + 1}',
          lastName: 'Test',
          avatar: 'https://example.com/avatar${index + 1}.jpg',
        ));
        
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => initialUsers);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => true);
        await provider.loadInitialUsers();
        reset(mockRepository);
      });

      test('should load more users when has more data', () async {
        // Arrange
        // Return 10 users to simulate a full page, so hasMore remains true
        final fullPageUsers = List.generate(10, (index) => User(
          id: index + 11, // Start from ID 11 since we already have 10 cached
          email: 'user${index + 11}@example.com',
          firstName: 'User${index + 11}',
          lastName: 'Test',
          avatar: 'https://example.com/avatar${index + 11}.jpg',
        ));
        
        when(() => mockRepository.getUsers(2, 10))
            .thenAnswer((_) async => fullPageUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await provider.loadMoreUsers();

        // Assert - should now have 20 users (10 initial + 10 more)
        expect(provider.visibleUsers.length, 20);
        expect(provider.isLoadingMore, false);
        expect(provider.hasMore, true);
        verify(() => mockRepository.getUsers(2, 10)).called(1);
        verify(() => mockRepository.cacheUsers(any(), any())).called(1);
      });

      test('should not load more when already loading', () async {
        // Arrange
        when(() => mockRepository.getUsers(any(), any()))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return List.generate(10, (index) => User(
            id: index + 11,
            email: 'user${index + 11}@example.com',
            firstName: 'User${index + 11}',
            lastName: 'Test',
            avatar: 'https://example.com/avatar${index + 11}.jpg',
          ));
        });

        // Act
        final future1 = provider.loadMoreUsers();
        final future2 = provider.loadMoreUsers();

        await Future.wait([future1, future2]);

        // Assert - should only call getUsers once due to loading state protection
        verify(() => mockRepository.getUsers(2, 10)).called(1);
      });
    });

    group('refreshUsers', () {
      setUp(() async {
        // Setup initial users first
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => true);
        await provider.loadInitialUsers();
        reset(mockRepository);
      });

      test('should refresh users from API', () async {
        // Arrange
        final refreshedUsers = [testUsers.first];
        when(() => mockRepository.getUsers(1, 10))
            .thenAnswer((_) async => refreshedUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await provider.refreshUsers();

        // Assert
        expect(provider.visibleUsers, refreshedUsers);
        expect(provider.isRefreshing, false);
        expect(provider.hasError, false);
        verify(() => mockRepository.getUsers(1, 10)).called(1);
        verify(() => mockRepository.cacheUsers(refreshedUsers, any())).called(1);
      });
    });

    group('search functionality', () {
      setUp(() async {
        // Setup initial users first
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => true);
        await provider.loadInitialUsers();
      });

      test('should filter users by name', () async {
        // Act
        provider.updateSearchQuery('John Doe');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert
        expect(provider.visibleUsers.length, 1);
        expect(provider.visibleUsers.first.firstName, 'John');
        expect(provider.searchQuery, 'John Doe');
      });

      test('should show all users when search query is empty', () async {
        // Act
        provider.updateSearchQuery('');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert
        expect(provider.visibleUsers, testUsers);
        expect(provider.searchQuery, '');
      });

      test('should show empty state when no users match search', () async {
        // Act
        provider.updateSearchQuery('Nonexistent');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert
        expect(provider.visibleUsers, isEmpty);
        expect(provider.isEmpty, true);
      });
    });

    group('retry functionality', () {
      test('should call loadInitialUsers when no users loaded', () async {
        // Arrange
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => []);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => false);
        when(() => mockRepository.getUsers(1, 10))
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        // Act
        provider.retry();

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockRepository.getUsers(1, 10)).called(1);
      });

      test('should call refreshUsers when users are already loaded', () async {
        // Arrange
        when(() => mockRepository.getCachedUsers())
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.isCacheValid())
            .thenAnswer((_) async => true);
        when(() => mockRepository.getUsers(1, 10))
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        await provider.loadInitialUsers();
        reset(mockRepository);

        when(() => mockRepository.getUsers(1, 10))
            .thenAnswer((_) async => testUsers);
        when(() => mockRepository.cacheUsers(any(), any()))
            .thenAnswer((_) async {});

        // Act
        provider.retry();

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockRepository.getUsers(1, 10)).called(1);
      });
    });
  });
}
