# ReqRes Users Flutter App

A complete Flutter application demonstrating clean architecture, modern state management, and robust data handling for a technical assessment.

## Features

- **User List Screen**: Paginated list of users with profile pictures, names, and emails
- **User Detail Screen**: Detailed view with full user information
- **Search**: Client-side search with 300ms debounce filtering by name
- **Infinite Scroll**: Automatic loading of next page when reaching bottom
- **Pull to Refresh**: Manual refresh functionality on list screen
- **Caching**: Hive-based local storage with 30-minute TTL and stale-while-revalidate strategy
- **Offline Handling**: Network connectivity detection and offline banner
- **Error Handling**: Comprehensive error states with retry functionality
- **Responsive UI**: Optimized for both phones and tablets
- **Clean Architecture**: Feature-first structure with separation of concerns

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── core/                     # Core utilities and infrastructure
│   ├── di/
│   │   └── service_locator.dart    # GetIt dependency injection
│   ├── network/
│   │   └── dio_client.dart         # Dio HTTP client configuration
│   ├── error/
│   │   ├── exceptions.dart         # Custom exceptions
│   │   └── failures.dart           # Domain failures
│   ├── constants/
│   │   ├── api_constants.dart      # API endpoints and configs
│   │   └── hive_constants.dart     # Hive configuration
│   └── utils/
│       ├── debouncer.dart          # Search debounce utility
│       └── connectivity_service.dart # Network connectivity
└── features/
    └── users/
        ├── data/
        │   ├── models/
        │   │   └── user_model.dart       # Hive model with adapters
        │   ├── datasources/
        │   │   ├── users_remote_data_source.dart  # API layer
        │   │   └── users_local_data_source.dart   # Cache layer
        │   └── repositories/
        │       └── users_repository_impl.dart     # Repository implementation
        ├── domain/
        │   ├── entities/
        │   │   └── user.dart               # Domain entity
        │   └── repositories/
        │       └── users_repository.dart   # Repository interface
        └── presentation/
            ├── providers/
            │   └── users_provider.dart     # Provider state management
            ├── pages/
            │   ├── users_list_page.dart    # Main list screen
            │   └── user_detail_page.dart   # Detail screen
            └── widgets/
                ├── user_list_item.dart     # List item widget
                └── state_widgets.dart      # Loading/error/empty states
```

### Architecture Layers

1. **Presentation Layer**: UI components and state management with Provider
2. **Domain Layer**: Business entities and repository interfaces
3. **Data Layer**: Data sources, models, and repository implementation
4. **Core Layer**: Shared utilities, networking, and infrastructure

## Technology Stack

- **State Management**: Provider (ChangeNotifier + ChangeNotifierProvider)
- **Networking**: Dio HTTP client with timeout and error handling
- **Dependency Injection**: GetIt service locator
- **Caching**: Hive with type adapters for local data persistence
- **Connectivity**: connectivity_plus for network status detection
- **Image Loading**: cached_network_image for profile pictures
- **Testing**: flutter_test with mocktail for mocking
- **Code Generation**: build_runner and hive_generator

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.5.4)
- Dart SDK (compatible with Flutter version)
- Internet connection for API calls

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bank_audi_technical_assessment
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Testing

### Run All Tests
```bash
flutter test
```

### Test Coverage

- **Data Layer Tests**: Repository implementation, error handling, cache operations
- **Provider Tests**: State management, search functionality, pagination
- **Widget Tests**: Basic UI component rendering

### Test Files
- `test/features/users/data/repositories/users_repository_impl_test.dart`
- `test/features/users/presentation/providers/users_provider_test.dart`
- `test/widget_test.dart`

## API Integration

### Endpoint
- **Base URL**: `https://reqres.in/api`
- **Users Endpoint**: `/users`
- **Pagination**: `?per_page=10&page=<pageNumber>`

### Response Format
```json
{
  "page": 1,
  "per_page": 6,
  "total": 12,
  "total_pages": 2,
  "data": [
    {
      "id": 1,
      "email": "george.bluth@reqres.in",
      "first_name": "George",
      "last_name": "Bluth",
      "avatar": "https://reqres.in/img/faces/1-image.jpg"
    }
  ]
}
```

## Caching Strategy

### Cache Implementation
- **Storage**: Hive local database with type adapters
- **Validity**: 30 minutes TTL
- **Strategy**: Stale-while-revalidate
  - Show cached data immediately on app start
  - Refresh in background if cache is stale
  - Update UI with fresh data when available

### Cache Operations
- `cacheUsers()`: Store user list with timestamp
- `getCachedUsers()`: Retrieve cached user list
- `isCacheValid()`: Check if cache is within validity period

## Search Implementation

### Features
- **Client-side filtering**: No API calls for search
- **Debounce**: 300ms delay to prevent excessive filtering
- **Case-insensitive**: Search matches regardless of case
- **Full name search**: Searches across first and last names

### Usage
Type in the search bar at the top of the user list screen. Results update automatically with debounce.

## Responsive Design

### Phone Layout
- Full-width content
- Standard touch targets
- Vertical scrolling

### Tablet Layout
- Constrained content width (600px max)
- Centered layout
- Larger touch targets and spacing

## Offline Handling

### Features
- **Connectivity Detection**: Real-time network status monitoring
- **Offline Banner**: Persistent notification when offline
- **Cached Data**: Show last available data when offline
- **Retry Functionality**: Manual retry buttons for failed operations

### Error Types
- Network errors (no internet)
- Timeout errors (slow connection)
- Server errors (API issues)
- Cache errors (storage problems)

## State Management

### UsersProvider States
- `isInitialLoading`: First-time data loading
- `isLoadingMore`: Pagination in progress
- `isRefreshing`: Pull-to-refresh in progress
- `hasMore`: More pages available
- `hasError`: Error state
- `isOffline`: No network connection
- `isEmpty`: No data available

### State Flow
1. App starts → Load cached data (if available)
2. If cache is stale → Background refresh
3. If no cache → Load from API
4. User interactions update state accordingly

## UI/UX Features

### Visual Design
- Material Design 3 theming
- Light theme only (as specified)
- Consistent spacing and typography
- Smooth animations and transitions

### User Experience
- Intuitive navigation
- Clear error messages
- Loading indicators for all async operations
- Pull-to-refresh gesture support
- Hero animations for profile pictures

## Troubleshooting

### Common Issues

1. **Build Runner Issues**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Hive Initialization Errors**
   - Ensure `Hive.initFlutter()` is called before any Hive operations
   - Verify all type adapters are registered

3. **Network Errors**
   - Check internet connection
   - Verify API endpoint accessibility
   - Review timeout configurations

### Debug Mode
Enable debug logging in `DioClient` by keeping the `LogInterceptor` active.

## License

This project is for technical assessment purposes only.

## Contributing

This is a solo project for technical assessment. No contributions are expected.

---

Built with Flutter
