import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/saved_posts/data/repositories/saved_posts_repository_impl.dart';
import 'package:pu_connection/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:pu_connection/features/saved_posts/presentation/cubit/saved_posts_state.dart';

void main() {
  group('SavedPostsState Tests', () {
    test('initial state defaults', () {
      const state = SavedPostsState();
      expect(state.status, SavedPostsStatus.initial);
      expect(state.savedPostIds, isEmpty);
      expect(state.isSaved('post_1'), isFalse);
    });

    test('isSaved returns true when postId is in set', () {
      const state = SavedPostsState(savedPostIds: {'p1', 'p2'});
      expect(state.isSaved('p1'), isTrue);
      expect(state.isSaved('p3'), isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = SavedPostsState();
      final updated = state.copyWith(
        status: SavedPostsStatus.loaded,
        savedPostIds: {'p1'},
        successMessage: 'Thành công',
      );
      expect(updated.status, SavedPostsStatus.loaded);
      expect(updated.savedPostIds.contains('p1'), isTrue);
      expect(updated.successMessage, 'Thành công');
    });
  });

  group('SavedPostsRepositoryImpl Tests', () {
    late SavedPostsRepositoryImpl repository;

    setUp(() {
      repository = SavedPostsRepositoryImpl(); // in-memory
    });

    test('savePost and unsavePost update in-memory store', () async {
      expect(await repository.isPostSaved('user_1', 'post_abc'), isFalse);

      await repository.savePost('user_1', 'post_abc');
      expect(await repository.isPostSaved('user_1', 'post_abc'), isTrue);

      final list = await repository.getSavedPostIds('user_1');
      expect(list.contains('post_abc'), isTrue);

      await repository.unsavePost('user_1', 'post_abc');
      expect(await repository.isPostSaved('user_1', 'post_abc'), isFalse);
    });

    test('watchSavedPostIds emits updated list on change', () async {
      final stream = repository.watchSavedPostIds('user_2');

      // Ghi nhận giá trị đầu tiên
      final future = stream.take(2).toList();
      await repository.savePost('user_2', 'post_xyz');

      final emitted = await future;
      expect(emitted.last.contains('post_xyz'), isTrue);
    });
  });

  group('SavedPostsCubit Tests', () {
    late SavedPostsRepositoryImpl repository;
    late SavedPostsCubit cubit;

    setUp(() {
      repository = SavedPostsRepositoryImpl();
      cubit = SavedPostsCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('init loads saved posts from repository', () async {
      await repository.savePost('cubit_user', 'p_100');

      cubit.init('cubit_user');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, SavedPostsStatus.loaded);
      expect(cubit.state.isSaved('p_100'), isTrue);
    });

    test('toggleSavePost toggles post state optimistically', () async {
      cubit.init('cubit_user_2');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.isSaved('p_200'), isFalse);

      await cubit.toggleSavePost('p_200');
      expect(cubit.state.isSaved('p_200'), isTrue);
      expect(cubit.state.successMessage, isNotNull);

      await cubit.toggleSavePost('p_200');
      expect(cubit.state.isSaved('p_200'), isFalse);
    });
  });
}
