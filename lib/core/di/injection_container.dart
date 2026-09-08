import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';
import '../localization/locale_cubit.dart';
import '../services/cloudinary_service.dart';
import '../services/gemini_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/feed/domain/repositories/post_repository.dart';
import '../../features/feed/data/repositories/post_repository_impl.dart';
import '../../features/feed/presentation/cubit/feed_cubit.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => CloudinaryService());
  sl.registerLazySingleton(() => GeminiService());

  sl.registerFactory(() => ThemeCubit(sharedPreferences: sl()));
  sl.registerFactory(() => LocaleCubit(sharedPreferences: sl()));

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerFactory(() => AuthCubit(authRepository: sl()));

  sl.registerLazySingleton<PostRepository>(() => PostRepositoryImpl());
  sl.registerFactory(() => FeedCubit(
        postRepository: sl(),
        cloudinaryService: sl(),
      ));
}
