import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/models/paginated_result.dart';
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

  /// Nhận diện các bài viết mẫu / tự tạo trước đây trên Bảng tin
  bool _isSeedOrDummyPost(PostEntity post) {
    final contentLower = post.content.toLowerCase().trim();

    // 1. Nhận diện theo ID hoặc tài khoản tác giả mẫu
    if (post.authorId == 'phenikaa_admin' ||
        post.authorId == 'student_2' ||
        post.authorId == 'phenikaa_union' ||
        post.authorId == 'pu_admin' ||
        post.authorId == 'pu_anonymous' ||
        post.authorStudentId == 'DOAN-PU' ||
        post.authorStudentId == '23020015' ||
        post.authorStudentId == 'CNTT-PU' ||
        post.authorStudentId == 'ENG-PU') {
      return true;
    }

    // 2. Nhận diện theo nội dung bài viết mẫu đã tự tạo trước đây
    if (contentLower.contains('chào các bạn sinh viên phenikaa!') &&
        contentLower.contains('cấu trúc dữ liệu & giải thuật')) {
      return true;
    }
    if (contentLower.contains('khoa ô tô') &&
        contentLower.contains('matlab & simulink')) {
      return true;
    }
    if (contentLower.contains('phenikaa innovation 2026') ||
        contentLower.contains('sáng tạo khởi nghiệp phenikaa')) {
      return true;
    }
    if (contentLower.startsWith('bài viết mẫu') ||
        contentLower.startsWith('test post') ||
        contentLower.startsWith('sample post') ||
        contentLower.startsWith('dummy post')) {
      return true;
    }

    return false;
  }

  @override
  Future<PaginatedResult<PostEntity>> getFeedPostsPaged({
    String? faculty,
    String? subjectCode,
    String? category,
    dynamic lastDocument,
    int limit = 15,
  }) async {
    Query query = _postsRef.orderBy('createdAt', descending: true);

    final hasCategory =
        category != null && category.isNotEmpty && category != 'Tất cả';
    final hasSubject = subjectCode != null && subjectCode.isNotEmpty;
    final hasFaculty =
        faculty != null && faculty.isNotEmpty && faculty != 'Tất cả';

    if (hasCategory) {
      query = query.where('category', isEqualTo: category);
    }
    if (hasSubject) {
      query = query.where('subjectCode', isEqualTo: subjectCode);
    }
    if (hasFaculty) {
      query = query.where('authorFaculty', isEqualTo: faculty);
    }

    if (lastDocument is DocumentSnapshot) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    try {
      final snapshot = await query.get();
      var posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Lọc các bài viết mẫu nếu có
      posts = posts.where((p) => !_isSeedOrDummyPost(p)).toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length >= limit;

      return PaginatedResult<PostEntity>(
        items: posts,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (_) {
      Query fallbackQuery = _postsRef.orderBy('createdAt', descending: true);
      if (lastDocument is DocumentSnapshot) {
        fallbackQuery = fallbackQuery.startAfterDocument(lastDocument);
      }
      fallbackQuery = fallbackQuery.limit(limit * 2);

      final snapshot = await fallbackQuery.get();
      var posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Lọc các bài viết mẫu nếu có
      posts = posts.where((p) => !_isSeedOrDummyPost(p)).toList();

      if (hasCategory) {
        posts = posts.where((p) => p.category == category).toList();
      }
      if (hasSubject) {
        posts = posts
            .where(
              (p) =>
                  p.subjectCode != null &&
                  p.subjectCode!.toLowerCase() == subjectCode.toLowerCase(),
            )
            .toList();
      }
      if (hasFaculty) {
        posts = posts
            .where(
              (p) => p.authorFaculty.toLowerCase() == faculty.toLowerCase(),
            )
            .toList();
      }

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length >= (limit * 2);

      return PaginatedResult<PostEntity>(
        items: posts,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    }
  }

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
          var posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();

          // Lọc bỏ các bài viết mẫu hoặc không hợp lệ mà không thực hiện side-effect xóa mạng trong Stream
          posts = posts.where((p) => !_isSeedOrDummyPost(p)).toList();

          if (category != null && category.isNotEmpty && category != 'Tất cả') {
            posts = posts.where((p) => p.category == category).toList();
          }

          if (subjectCode != null && subjectCode.isNotEmpty) {
            posts = posts
                .where(
                  (p) =>
                      p.subjectCode != null &&
                      p.subjectCode!.toLowerCase() == subjectCode.toLowerCase(),
                )
                .toList();
          }

          if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
            posts = posts
                .where(
                  (p) => p.authorFaculty.toLowerCase() == faculty.toLowerCase(),
                )
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
      taggedUserIds: post.taggedUserIds,
      taggedUserNames: post.taggedUserNames,
      likedUsers: const [],
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
    );

    final docRef = await _postsRef.add(model.toMap());

    // Tự động đồng bộ các tệp tài liệu đính kèm (pdf, doc, ppt, xls, zip...) sang Kho tài liệu
    final docAttachments = post.attachments
        .where((a) => a.type.toLowerCase() != 'image')
        .toList();
    if (docAttachments.isNotEmpty) {
      final docsRef = _firestore.collection(
        FirebaseConstants.studyDocumentsCollection,
      );
      for (final att in docAttachments) {
        try {
          final cleanTitle = att.name.isNotEmpty
              ? att.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
              : (post.content.trim().isNotEmpty
                    ? (post.content.trim().split('\n').first)
                    : 'Tài liệu chia sẻ');

          final subjectCode = post.subjectCode?.trim().isNotEmpty == true
              ? post.subjectCode!.trim().toUpperCase()
              : 'CHUNG';

          final faculty = post.authorFaculty.trim().isNotEmpty
              ? post.authorFaculty.trim()
              : 'Công nghệ thông tin';

          await docsRef.add({
            'title': cleanTitle.length > 80
                ? '${cleanTitle.substring(0, 80)}...'
                : cleanTitle,
            'code': subjectCode,
            'faculty': faculty,
            'fileUrl': att.url,
            'fileType': att.type.toLowerCase(),
            'fileSize': 'Đính kèm Feed',
            'authorId': post.authorId,
            'authorName': post.authorName,
            'authorStudentId': post.authorStudentId,
            'downloads': 0,
            'rating': 5.0,
            'description':
                'Đồng bộ từ bài viết Bảng tin: "${post.content.length > 120 ? '${post.content.substring(0, 120)}...' : post.content}"',
            'originPostId': docRef.id,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    }

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

    // Dọn dẹp các tài liệu đã được đồng bộ từ bài viết này
    try {
      final snap = await _firestore
          .collection(FirebaseConstants.studyDocumentsCollection)
          .where('originPostId', isEqualTo: postId)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
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
      'taggedUserIds': post.taggedUserIds,
      'taggedUserNames': post.taggedUserNames,
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
    final commentsCol = docRef.collection(FirebaseConstants.commentsSubcollection);
    final commentDocRef = comment.commentId.isNotEmpty
        ? commentsCol.doc(comment.commentId)
        : commentsCol.doc();
    final toSave = comment.commentId.isEmpty
        ? comment.copyWith(commentId: commentDocRef.id)
        : comment;

    await commentDocRef.set(toSave.toMap());
    try {
      await docRef.update({'commentCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  @override
  Future<void> toggleLikeComment({
    required String postId,
    required String commentId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    final commentRef = _postsRef
        .doc(postId)
        .collection(FirebaseConstants.commentsSubcollection)
        .doc(commentId);

    if (isCurrentlyLiked) {
      await commentRef.update({
        'likeCount': FieldValue.increment(-1),
        'likedUserIds': FieldValue.arrayRemove([userId]),
      });
    } else {
      await commentRef.update({
        'likeCount': FieldValue.increment(1),
        'likedUserIds': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef = _postsRef.doc(postId);
    await postRef
        .collection(FirebaseConstants.commentsSubcollection)
        .doc(commentId)
        .delete();

    try {
      await postRef.update({'commentCount': FieldValue.increment(-1)});
    } catch (_) {}
  }

  @override
  Future<void> editComment({
    required String postId,
    required String commentId,
    required String newContent,
  }) async {
    final commentRef = _postsRef
        .doc(postId)
        .collection(FirebaseConstants.commentsSubcollection)
        .doc(commentId);

    await commentRef.update({
      'content': newContent,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
