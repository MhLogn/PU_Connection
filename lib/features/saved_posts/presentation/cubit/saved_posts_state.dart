enum SavedPostsStatus { initial, loading, loaded, error }

class SavedPostsState {
  final SavedPostsStatus status;
  final Set<String> savedPostIds;
  final String? errorMessage;
  final String? successMessage;

  const SavedPostsState({
    this.status = SavedPostsStatus.initial,
    this.savedPostIds = const {},
    this.errorMessage,
    this.successMessage,
  });

  bool isSaved(String postId) => savedPostIds.contains(postId);

  SavedPostsState copyWith({
    SavedPostsStatus? status,
    Set<String>? savedPostIds,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SavedPostsState(
      status: status ?? this.status,
      savedPostIds: savedPostIds ?? this.savedPostIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
