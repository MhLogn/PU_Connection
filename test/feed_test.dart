import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/models/paginated_result.dart';
import 'package:pu_connection/core/services/cloudinary_service.dart';
import 'package:pu_connection/features/feed/data/models/post_model.dart';
import 'package:pu_connection/features/feed/domain/entities/comment_entity.dart';
import 'package:pu_connection/features/feed/domain/entities/post_entity.dart';
import 'package:pu_connection/features/feed/domain/repositories/post_repository.dart';
import 'package:pu_connection/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:pu_connection/features/feed/presentation/cubit/feed_state.dart';

void main() {
  group('PostAttachment Tests', () {
    test('converts to Map and from Map correctly', () {
      const att = PostAttachment(
        url: 'https://cloudinary.com/slide.pptx',
        name: 'Slide_Bai_Giang.pptx',
        type: 'pptx',
        sizeBytes: 1048576,
      );

      final map = att.toMap();
      expect(map['url'], 'https://cloudinary.com/slide.pptx');
      expect(map['name'], 'Slide_Bai_Giang.pptx');
      expect(map['type'], 'pptx');
      expect(map['sizeBytes'], 1048576);

      final reconstructed = PostAttachment.fromMap(map);
      expect(reconstructed.url, att.url);
      expect(reconstructed.name, att.name);
      expect(reconstructed.type, att.type);
      expect(reconstructed.sizeBytes, att.sizeBytes);
    });
  });

  group('PostModel & PostEntity Tests', () {
    final now = DateTime(2026, 9, 24, 8, 30);
    final post = PostModel(
      postId: 'post_123',
      authorId: 'user_456',
      authorName: 'Nguyễn Văn A',
      authorStudentId: '23010390',
      authorFaculty: 'Khoa Công nghệ thông tin',
      content: 'Tài liệu ôn thi cuối kỳ Giải tích 1',
      category: 'Tài liệu',
      subjectCode: 'MATH-101',
      attachments: const [
        PostAttachment(
          url: 'https://cloudinary.com/doc.pdf',
          name: 'De_thi_giai_tich.pdf',
          type: 'pdf',
          sizeBytes: 2048,
        ),
      ],
      tags: const ['GiaiTich', 'Phenikaa'],
      likedUsers: const ['user_789'],
      likeCount: 1,
      commentCount: 0,
      createdAt: now,
    );

    test('isLikedBy correctly identifies user like status', () {
      expect(post.isLikedBy('user_789'), isTrue);
      expect(post.isLikedBy('user_999'), isFalse);
    });

    test('copyWith updates specified fields', () {
      final updated = post.copyWith(
        content: 'Tài liệu đã được cập nhật bản mới nhất',
        category: 'Thảo luận',
        likeCount: 2,
      );

      expect(updated.content, 'Tài liệu đã được cập nhật bản mới nhất');
      expect(updated.category, 'Thảo luận');
      expect(updated.likeCount, 2);
      expect(updated.postId, post.postId);
      expect(updated.authorName, post.authorName);
    });

    test('PostModel converts to Map and from Map correctly', () {
      final map = post.toMap();
      expect(map['authorName'], 'Nguyễn Văn A');
      expect(map['subjectCode'], 'MATH-101');
      expect(map['category'], 'Tài liệu');
      expect((map['attachments'] as List).length, 1);

      final fromMap = PostModel.fromMap(map, 'post_123');
      expect(fromMap.postId, 'post_123');
      expect(fromMap.authorName, 'Nguyễn Văn A');
      expect(fromMap.subjectCode, 'MATH-101');
      expect(fromMap.attachments.first.name, 'De_thi_giai_tich.pdf');
    });

    test('PostModel correctly handles tagged users serialization', () {
      final taggedPost = post.copyWith(
        taggedUserIds: ['user_789', 'user_999'],
        taggedUserNames: {'user_789': 'Trần Thị Mai', 'user_999': 'Lê Hoàng Nam'},
      );

      final map = taggedPost.toMap();
      expect(map['taggedUserIds'], ['user_789', 'user_999']);
      expect(map['taggedUserNames'], {'user_789': 'Trần Thị Mai', 'user_999': 'Lê Hoàng Nam'});

      final reconstructed = PostModel.fromMap(map, 'post_tagged');
      expect(reconstructed.taggedUserIds.length, 2);
      expect(reconstructed.taggedUserNames['user_789'], 'Trần Thị Mai');
      expect(reconstructed.taggedUserNames['user_999'], 'Lê Hoàng Nam');
    });
  });

  group('FeedCubit Pagination Tests', () {
    late _MockPostRepository mockRepo;
    late FeedCubit feedCubit;

    setUp(() {
      mockRepo = _MockPostRepository();
      feedCubit = FeedCubit(
        postRepository: mockRepo,
        cloudinaryService: CloudinaryService(),
      );
    });

    tearDown(() {
      feedCubit.close();
    });

    test('loadFeed fetches initial 15 items and sets hasMore correctly', () async {
      await feedCubit.loadFeed();

      expect(feedCubit.state, isA<FeedLoaded>());
      final state = feedCubit.state as FeedLoaded;
      expect(state.posts.length, 15);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
    });

    test('loadMorePosts appends next page and updates hasMore', () async {
      await feedCubit.loadFeed();
      await feedCubit.loadMorePosts();

      final state = feedCubit.state as FeedLoaded;
      expect(state.posts.length, 20); // 15 + 5 remaining
      expect(state.hasMore, false); // Less than 15 returned, so hasMore is false
    });
  });
}

class _MockPostRepository implements PostRepository {
  final List<PostEntity> _allPosts = List.generate(
    20,
    (i) => PostEntity(
      postId: 'post_$i',
      authorId: 'author_$i',
      authorName: 'Sinh viên $i',
      content: 'Nội dung bài viết số $i',
      category: 'Thảo luận',
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
    ),
  );

  @override
  Future<PaginatedResult<PostEntity>> getFeedPostsPaged({
    String? faculty,
    String? subjectCode,
    String? category,
    dynamic lastDocument,
    int limit = 15,
  }) async {
    int startIndex = 0;
    if (lastDocument != null && lastDocument is int) {
      startIndex = lastDocument;
    }
    final endIndex = (startIndex + limit).clamp(0, _allPosts.length);
    final slice = _allPosts.sublist(startIndex, endIndex);

    return PaginatedResult<PostEntity>(
      items: slice,
      lastDocument: endIndex,
      hasMore: endIndex < _allPosts.length,
    );
  }

  @override
  Stream<List<PostEntity>> getFeedPosts({String? faculty, String? subjectCode, String? category}) {
    return Stream.value(_allPosts);
  }

  @override
  Future<void> createPost(PostEntity post) async {}

  @override
  Future<void> toggleLikePost({required String postId, required String userId, required bool isCurrentlyLiked}) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> updatePost(PostEntity post) async {}

  @override
  Stream<List<CommentEntity>> getComments(String postId) => Stream.value([]);

  @override
  Future<void> addComment(String postId, CommentEntity comment) async {}
}
