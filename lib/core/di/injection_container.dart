import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';
import '../localization/locale_cubit.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerFactory(() => ThemeCubit(sharedPreferences: sl()));
  sl.registerFactory(() => LocaleCubit(sharedPreferences: sl()));
}
