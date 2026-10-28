import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';
import '../localization/locale_cubit.dart';
import '../services/cloudinary_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/offline_cache_service.dart';
import '../services/bad_words_filter_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/feed/domain/repositories/post_repository.dart';
import '../../features/feed/data/repositories/post_repository_impl.dart';
import '../../features/feed/presentation/cubit/feed_cubit.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/presentation/cubit/document_cubit.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/clubs/domain/repositories/club_repository.dart';
import '../../features/clubs/data/repositories/club_repository_impl.dart';
import '../../features/clubs/presentation/cubit/club_cubit.dart';
import '../../features/friends/domain/repositories/friend_repository.dart';
import '../../features/friends/data/repositories/friend_repository_impl.dart';
import '../../features/friends/presentation/cubit/friendship_cubit.dart';
import '../../features/moderation/domain/repositories/moderation_repository.dart';
import '../../features/moderation/data/repositories/moderation_repository_impl.dart';
import '../../features/moderation/presentation/cubit/moderation_cubit.dart';
import '../../features/notifications/domain/repositories/in_app_notification_repository.dart';
import '../../features/notifications/data/repositories/in_app_notification_repository_impl.dart';
import '../../features/notifications/presentation/cubit/in_app_notifications_cubit.dart';
import '../../features/saved_posts/domain/repositories/saved_posts_repository.dart';
import '../../features/saved_posts/data/repositories/saved_posts_repository_impl.dart';
import '../../features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import '../../features/study_groups/domain/repositories/study_group_repository.dart';
import '../../features/study_groups/data/repositories/study_group_repository_impl.dart';
import '../../features/study_groups/presentation/cubit/study_group_cubit.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/presentation/cubit/notes_cubit.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => CloudinaryService());
  sl.registerLazySingleton(() => GeminiService());
  sl.registerLazySingleton(() => OfflineCacheService(prefs: sl()));
  sl.registerLazySingleton(() => BadWordsFilterService());

  final notificationService = NotificationService(prefs: sl());
  await notificationService.init();
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  sl.registerFactory(() => ThemeCubit(sharedPreferences: sl()));
  sl.registerFactory(() => LocaleCubit(sharedPreferences: sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(prefs: sl()),
  );
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository: sl()));

  sl.registerLazySingleton<PostRepository>(() => PostRepositoryImpl());
  sl.registerFactory(
    () => FeedCubit(postRepository: sl(), cloudinaryService: sl()),
  );

  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(cloudinaryService: sl()),
  );
  sl.registerFactory(() => DocumentCubit(documentRepository: sl()));

  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  sl.registerFactory(
    () => ChatCubit(chatRepository: sl(), cloudinaryService: sl()),
  );

  // Clubs
  sl.registerLazySingleton<ClubRepository>(() => ClubRepositoryImpl());
  sl.registerFactory(() => ClubCubit(clubRepository: sl()));

  // Friends & Relationships
  sl.registerLazySingleton<FriendRepository>(() => FriendRepositoryImpl());
  sl.registerFactory(() => FriendshipCubit(friendRepository: sl()));

  // Content Moderation & Blocking
  sl.registerLazySingleton<ModerationRepository>(
    () => ModerationRepositoryImpl(),
  );
  sl.registerFactory(() => ModerationCubit(moderationRepository: sl()));

  // In-App Notification Center
  sl.registerLazySingleton<InAppNotificationRepository>(
    () => InAppNotificationRepositoryImpl(),
  );
  sl.registerFactory(() => InAppNotificationsCubit(repository: sl()));

  // Saved Posts (Bookmarks)
  sl.registerLazySingleton<SavedPostsRepository>(
    () => SavedPostsRepositoryImpl(),
  );
  sl.registerFactory(() => SavedPostsCubit(repository: sl()));

  // Study Group Matchmaker
  sl.registerLazySingleton<StudyGroupRepository>(
    () => StudyGroupRepositoryImpl(),
  );
  sl.registerFactory(() => StudyGroupCubit(repository: sl()));

  // Notes
  sl.registerLazySingleton<NoteRepository>(() => NoteRepositoryImpl());
  sl.registerFactory(() => NotesCubit(noteRepository: sl()));

  // Admin Portal & Moderation Management
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl());
  sl.registerFactory(() => AdminCubit(adminRepository: sl()));
}
