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
    Query query = _postsRef.orderBy('createdAt', descending: true).limit(50);

    if (category != null && category != 'Tất cả') {
      query = query.where('category', isEqualTo: category);
    }

    if (subjectCode != null && subjectCode.isNotEmpty) {
      query = query.where('subjectCode', isEqualTo: subjectCode);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
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

  @override
  Future<void> seedMockPostsIfEmpty(String currentUserId, String currentUserName) async {
    final snapshot = await _postsRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final mockPosts = [
        PostModel(
          postId: '',
          authorId: currentUserId.isNotEmpty ? currentUserId : 'phenikaa_mod',
          authorName: currentUserName.isNotEmpty ? currentUserName : 'Ban Học Tập Phenikaa',
          authorStudentId: '21010001',
          authorFaculty: 'Công nghệ thông tin',
          content: 'Chào các bạn sinh viên Phenikaa! 🚀\nTổng hợp tài liệu ôn tập và đề thi mẫu môn Cấu trúc dữ liệu & Giải thuật kỳ này đã được cập nhật. Chúc các bạn ôn thi đạt kết quả tốt nhất!',
          postType: 'document',
          category: 'Tài liệu',
          subjectCode: 'CNTT-202',
          likeCount: 15,
          commentCount: 4,
          tags: const ['#Phenikaa', '#CTDL', '#OnThi'],
          likedUsers: const [],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostModel(
          postId: '',
          authorId: 'student_2',
          authorName: 'Trần Minh Anh',
          authorStudentId: '22010456',
          authorFaculty: 'Kỹ thuật Ô tô & Năng lượng',
          content: 'Có nhóm đồ án nào của K16 khoa Ô tô đang cần thêm người mảng mô phỏng động cơ không ạ? Mình đã nắm vững MATLAB & Simulink, rất mong muốn được ghép nhóm cùng các bạn.',
          postType: 'text',
          category: 'Tìm nhóm',
          subjectCode: 'OTO-301',
          likeCount: 8,
          commentCount: 2,
          tags: const ['#TimNhom', '#OTo', '#K16'],
          likedUsers: const [],
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        PostModel(
          postId: '',
          authorId: 'phenikaa_union',
          authorName: 'Đoàn Thanh Niên Phenikaa',
          authorStudentId: 'DOAN-PU',
          authorFaculty: 'Khoa học cơ bản',
          content: '📢 THÔNG BÁO: Cuộc thi Sáng tạo Khởi nghiệp Phenikaa Innovation 2026 chính thức mở đơn đăng ký! Các đội thi xuất sắc sẽ có cơ hội nhận giải thưởng lên đến 50.000.000 VNĐ cùng sự bảo trợ từ Phenikaa Group.',
          postType: 'text',
          category: 'Thông báo',
          subjectCode: null,
          likeCount: 42,
          commentCount: 9,
          tags: const ['#PhenikaaInnovation', '#KhoiNghiep', '#TuHaoPhenikaa'],
          likedUsers: const [],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      for (final post in mockPosts) {
        await _postsRef.add(post.toMap());
      }
    }
  }
}
