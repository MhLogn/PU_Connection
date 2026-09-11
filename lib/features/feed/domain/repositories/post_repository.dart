import '../entities/comment_entity.dart';
import '../entities/post_entity.dart';

abstract class PostRepository {
  Stream<List<PostEntity>> getFeedPosts({
    String? faculty,
    String? subjectCode,
    String? category,
  });

  Future<void> createPost(PostEntity post);

  Future<void> toggleLikePost({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
  });

  Future<void> deletePost(String postId);

  Stream<List<CommentEntity>> getComments(String postId);

  Future<void> addComment(String postId, CommentEntity comment);
}
