import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../../../../core/constants/hive_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class UsersLocalDataSource {
  Future<void> cacheUsers(List<UserModel> users);
  Future<List<UserModel>> getCachedUsers();
  Future<void> cacheTimestamp(DateTime timestamp);
  Future<DateTime?> getCachedTimestamp();
  Future<void> clearCache();
}

class UsersLocalDataSourceImpl implements UsersLocalDataSource {
  final Box<UserModel> _usersBox;
  final Box<String> _timestampBox;

  UsersLocalDataSourceImpl(this._usersBox, this._timestampBox);

  @override
  Future<void> cacheUsers(List<UserModel> users) async {
    try {
      await _usersBox.clear();
      for (final user in users) {
        await _usersBox.add(user);
      }
    } catch (e) {
      throw CacheException('Failed to cache users: $e');
    }
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    try {
      return _usersBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get cached users: $e');
    }
  }

  @override
  Future<void> cacheTimestamp(DateTime timestamp) async {
    try {
      await _timestampBox.put(HiveConstants.cacheTimestampKey, timestamp.toIso8601String());
    } catch (e) {
      throw CacheException('Failed to cache timestamp: $e');
    }
  }

  @override
  Future<DateTime?> getCachedTimestamp() async {
    try {
      final timestampString = _timestampBox.get(HiveConstants.cacheTimestampKey);
      return timestampString != null ? DateTime.parse(timestampString) : null;
    } catch (e) {
      throw CacheException('Failed to get cached timestamp: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _usersBox.clear();
      await _timestampBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}
