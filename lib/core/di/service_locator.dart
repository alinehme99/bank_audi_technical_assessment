import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../network/dio_client.dart';
import '../utils/connectivity_service.dart';
import '../../features/users/data/datasources/users_local_data_source.dart';
import '../../features/users/data/datasources/users_remote_data_source.dart';
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import '../../features/users/presentation/providers/users_provider.dart';
import '../../features/users/data/models/user_model.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => ConnectivityService());

  // Hive setup
  final usersBox = await Hive.openBox<UserModel>('users_box');
  final timestampBox = await Hive.openBox<String>('cache_timestamp_box');
  
  // Data sources
  sl.registerLazySingleton(
    () => UsersRemoteDataSourceImpl(sl<DioClient>()),
  );
  
  sl.registerLazySingleton(
    () => UsersLocalDataSourceImpl(usersBox, timestampBox),
  );

  // Repository
  sl.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(
      remoteDataSource: sl<UsersRemoteDataSourceImpl>(),
      localDataSource: sl<UsersLocalDataSourceImpl>(),
    ),
  );

  // Providers
  sl.registerFactory(
    () => UsersProvider(sl<UsersRepository>()),
  );
}
