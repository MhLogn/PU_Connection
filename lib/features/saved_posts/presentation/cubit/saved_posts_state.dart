enum SavedPostsStatus { initial, loading, loaded, error }

class SavedPostsState {
  final SavedPostsStatus status;
  final Set<String> savedPostIds;
  final Set<String> viewedSavedPostIds;
  final String? errorMessage;
  final String? successMessage;

  const SavedPostsState({
    this.status = SavedPostsStatus.initial,
    this.savedPostIds = const {},
    this.viewedSavedPostIds = const {},
    this.errorMessage,
    this.successMessage,
  });

  bool isSaved(String postId) => savedPostIds.contains(postId);
  int get unviewedCount => savedPostIds.difference(viewedSavedPostIds).length;

  SavedPostsState copyWith({
    SavedPostsStatus? status,
    Set<String>? savedPostIds,
    Set<String>? viewedSavedPostIds,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SavedPostsState(
      status: status ?? this.status,
      savedPostIds: savedPostIds ?? this.savedPostIds,
      viewedSavedPostIds: viewedSavedPostIds ?? this.viewedSavedPostIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
