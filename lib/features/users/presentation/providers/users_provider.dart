import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/entities/user.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/repositories/users_repository.dart';
import 'package:bank_audi_technical_assessment/core/utils/debouncer.dart';
import 'package:bank_audi_technical_assessment/core/constants/api_constants.dart';
import 'package:bank_audi_technical_assessment/core/error/failures.dart';

class UsersProvider extends ChangeNotifier {
  final UsersRepository _repository;
  final Debouncer _debouncer;

  UsersProvider(this._repository) : _debouncer = Debouncer();

  List<User> _allUsers = [];
  List<User> _visibleUsers = [];
  int _currentPage = 1;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isOffline = false;

  // Getters
  List<User> get visibleUsers => _visibleUsers;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isInitialLoading && _visibleUsers.isEmpty && !hasError;

  Future<void> loadInitialUsers() async {
    if (_isInitialLoading || _isRefreshing) return;

    _setInitialLoading(true);
    _clearError();

    try {
      // Try to load cached users first
      final cachedUsers = await _repository.getCachedUsers();
      final isCacheValid = await _repository.isCacheValid();
      
      if (cachedUsers.isNotEmpty) {
        _allUsers = cachedUsers;
        
        // Restore pagination state based on cached users
        if (cachedUsers.length >= ApiConstants.perPage) {
          _currentPage = (cachedUsers.length / ApiConstants.perPage).ceil();
          _hasMore = cachedUsers.length % ApiConstants.perPage == 0;
        } else {
          _currentPage = 1;
          _hasMore = false; // Less than full page means no more pages
        }
        
        _applySearchFilter();
        
        // If cache is stale, refresh in background
        if (!isCacheValid) {
          _refreshFromApi();
        }
      } else {
        // No cache, load from API
        await _loadFromApi(page: 1, isRefresh: true);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setInitialLoading(false);
    }
  }

  Future<void> loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore || _isRefreshing) return;

    _setLoadingMore(true);
    _clearError();

    try {
      await _loadFromApi(page: _currentPage + 1, isRefresh: false);
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoadingMore(false);
    }
  }

  Future<void> refreshUsers() async {
    if (_isRefreshing || _isInitialLoading) return;

    _setRefreshing(true);
    _clearError();

    try {
      await _loadFromApi(page: 1, isRefresh: true);
    } catch (e) {
      _handleError(e);
    } finally {
      _setRefreshing(false);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _debouncer.run(() {
      _applySearchFilter();
    });
  }

  void retry() {
    if (_allUsers.isEmpty) {
      loadInitialUsers();
    } else {
      refreshUsers();
    }
  }

  Future<void> _loadFromApi({required int page, required bool isRefresh}) async {
    try {
      final users = await _repository.getUsers(page, ApiConstants.perPage);
      
      if (isRefresh) {
        _allUsers = users;
        _currentPage = 1;
      } else {
        _allUsers.addAll(users);
        _currentPage = page;
      }

      // Cache the users
      await _repository.cacheUsers(_allUsers, DateTime.now());

      // Check if there are more pages
      _hasMore = users.length == ApiConstants.perPage;

      _applySearchFilter();
      _setOffline(false);
    } catch (e) {
      // Re-throw the exception to be handled by the calling methods
      rethrow;
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      await _loadFromApi(page: 1, isRefresh: true);
    } catch (e) {
      // Don't show error for background refresh
    }
  }

  void _applySearchFilter() async {
    if (_searchQuery.isEmpty) {
      _visibleUsers = List.from(_allUsers);
    } else {
      // First search in loaded users
      var searchResults = _allUsers.where((user) {
        return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      // If no results in loaded users, search all cached users
      if (searchResults.isEmpty) {
        try {
          final allCachedUsers = await _repository.getCachedUsers();
          searchResults = allCachedUsers.where((user) {
            return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        } catch (e) {
          // If cache fails, just use loaded users results
        }
      }
      
      _visibleUsers = searchResults;
    }
    notifyListeners();
  }

  void _handleError(dynamic error) {
    if (error is NetworkFailure) {
      _setError('Please check your internet connection and try again.');
      _setOffline(true);
    } else if (error is TimeoutFailure) {
      _setError('Request timed out. Please check your connection and try again.');
      _setOffline(true);
    } else if (error is ServerFailure) {
      _setError('Server error: ${error.message}');
      _setOffline(false);
    } else if (error is CacheFailure) {
      _setError('Storage error: ${error.message}');
      _setOffline(false);
    } else if (error.toString().contains('NetworkException') || 
               error.toString().contains('connection') ||
               error.toString().contains('internet')) {
      _setError('Please check your internet connection and try again.');
      _setOffline(true);
    } else {
      _setError('Something went wrong. Please check your connection and try again.');
      _setOffline(true);
    }
  }

  void _setInitialLoading(bool loading) {
    _isInitialLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setOffline(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
