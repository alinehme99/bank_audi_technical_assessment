import '../entities/user.dart';

abstract class UsersRepository {
  Future<List<User>> getUsers(int page, int perPage);
  Future<List<User>> getCachedUsers();
  Future<void> cacheUsers(List<User> users, DateTime timestamp);
  Future<DateTime?> getCachedTimestamp();
  Future<bool> isCacheValid();
}
