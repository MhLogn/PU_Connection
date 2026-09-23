import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final FirebaseFirestore _firestore;

  PostRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _postsRef =>
      _firestore.collection(FirebaseConstants.postsCollection);

  @override
  Stream<List<PostEntity>> getFeedPosts({
    String? faculty,
    String? subjectCode,
    String? category,
  }) {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      var posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      if (category != null && category.isNotEmpty && category != 'Tất cả') {
        posts = posts.where((p) => p.category == category).toList();
      }

      if (subjectCode != null && subjectCode.isNotEmpty) {
        posts = posts
            .where((p) =>
                p.subjectCode != null &&
                p.subjectCode!.toLowerCase() == subjectCode.toLowerCase())
            .toList();
      }

      if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
        posts = posts
            .where((p) => p.authorFaculty.toLowerCase() == faculty.toLowerCase())
            .toList();
      }

      return posts;
    });
  }

  @override
  Future<void> createPost(PostEntity post) async {
    final model = PostModel(
      postId: post.postId,
      authorId: post.authorId,
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      authorStudentId: post.authorStudentId,
      authorFaculty: post.authorFaculty,
      content: post.content,
      postType: post.postType,
      category: post.category,
      subjectCode: post.subjectCode,
      attachments: post.attachments,
      tags: post.tags,
      likedUsers: const [],
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
    );

    await _postsRef.add(model.toMap());

    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(post.authorId)
          .update({'postsCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  @override
  Future<void> toggleLikePost({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    final docRef = _postsRef.doc(postId);

    if (isCurrentlyLiked) {
      await docRef.update({
        'likeCount': FieldValue.increment(-1),
        'likedUsers': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'likeCount': FieldValue.increment(1),
        'likedUsers': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }

  @override
  Future<void> updatePost(PostEntity post) async {
    final docRef = _postsRef.doc(post.postId);
    await docRef.update({
      'content': post.content,
      'category': post.category,
      'subjectCode': post.subjectCode,
      'attachments': post.attachments.map((a) => a.toMap()).toList(),
      'tags': post.tags,
      'postType': post.postType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CommentEntity>> getComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection(FirebaseConstants.commentsSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CommentEntity.fromMap(data, id: doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addComment(String postId, CommentEntity comment) async {
    final docRef = _postsRef.doc(postId);
    await docRef.collection(FirebaseConstants.commentsSubcollection).add(comment.toMap());
    try {
      await docRef.update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }
}
