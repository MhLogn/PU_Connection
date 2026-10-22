import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/saved_posts_repository.dart';
import 'saved_posts_state.dart';

class SavedPostsCubit extends Cubit<SavedPostsState> {
  final SavedPostsRepository _repository;
  StreamSubscription<List<String>>? _subscription;
  String? _currentUserId;

  SavedPostsCubit({
    required SavedPostsRepository repository,
  })  : _repository = repository,
        super(const SavedPostsState());

  String? get currentUserId => _currentUserId;

  void init(String userId) {
    if (userId.isEmpty) return;
    if (_currentUserId == userId && _subscription != null) return;

    _currentUserId = userId;
    _subscription?.cancel();

    emit(state.copyWith(status: SavedPostsStatus.loading));

    _subscription = _repository.watchSavedPostIds(userId).listen(
      (postIds) {
        emit(state.copyWith(
          status: SavedPostsStatus.loaded,
          savedPostIds: postIds.toSet(),
        ));
      },
      onError: (err) {
        emit(state.copyWith(
          status: SavedPostsStatus.error,
          errorMessage: err.toString(),
        ));
      },
    );
  }

  Future<void> toggleSavePost(String postId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty || postId.isEmpty) return;

    final wasSaved = state.isSaved(postId);
    final updatedSet = Set<String>.from(state.savedPostIds);

    // Optimistic update
    if (wasSaved) {
      updatedSet.remove(postId);
      emit(state.copyWith(
        savedPostIds: updatedSet,
        successMessage: 'Đã bỏ lưu bài viết',
      ));
      try {
        await _repository.unsavePost(userId, postId);
      } catch (e) {
        // Rollback nếu lỗi
        updatedSet.add(postId);
        emit(state.copyWith(
          savedPostIds: updatedSet,
          errorMessage: 'Lỗi khi bỏ lưu bài viết: $e',
        ));
      }
    } else {
      updatedSet.add(postId);
      emit(state.copyWith(
        savedPostIds: updatedSet,
        successMessage: 'Đã lưu bài viết vào danh sách yêu thích',
      ));
      try {
        await _repository.savePost(userId, postId);
      } catch (e) {
        // Rollback nếu lỗi
        updatedSet.remove(postId);
        emit(state.copyWith(
          savedPostIds: updatedSet,
          errorMessage: 'Lỗi khi lưu bài viết: $e',
        ));
      }
    }
  }

  void clearMessage() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
