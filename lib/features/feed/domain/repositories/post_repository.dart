import '../entities/comment_entity.dart';
import '../entities/post_entity.dart';

abstract class PostRepository {
  /// Lắng nghe luồng dữ liệu bài viết thời gian thực từ Firestore
  Stream<List<PostEntity>> getFeedPosts({
    String? faculty,
    String? subjectCode,
    String? category,
  });

  /// Đăng bài viết mới
  Future<void> createPost(PostEntity post);

  /// Thả / Bỏ like bài viết (sử dụng FieldValue.increment hoàn toàn 0 đồng)
  Future<void> toggleLikePost({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
  });

  /// Xóa bài viết
  Future<void> deletePost(String postId);

  /// Lắng nghe bình luận theo bài viết
  Stream<List<CommentEntity>> getComments(String postId);

  /// Gửi bình luận cho bài viết
  Future<void> addComment(String postId, CommentEntity comment);

  /// Tự động sinh dữ liệu mẫu Phenikaa nếu bảng tin chưa có dữ liệu
  Future<void> seedMockPostsIfEmpty(String currentUserId, String currentUserName);
}
