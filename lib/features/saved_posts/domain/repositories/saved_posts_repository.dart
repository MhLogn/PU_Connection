abstract class SavedPostsRepository {
  /// Lắng nghe danh sách postId mà người dùng đã lưu
  Stream<List<String>> watchSavedPostIds(String userId);

  /// Lấy danh sách postId đã lưu một lần
  Future<List<String>> getSavedPostIds(String userId);

  /// Lưu bài viết
  Future<void> savePost(String userId, String postId);

  /// Bỏ lưu bài viết
  Future<void> unsavePost(String userId, String postId);

  /// Kiểm tra xem bài viết đã được lưu chưa
  Future<bool> isPostSaved(String userId, String postId);
}
