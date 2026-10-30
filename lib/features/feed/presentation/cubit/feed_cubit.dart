import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/domain/entities/notification_type.dart';
import '../../../notifications/domain/repositories/in_app_notification_repository.dart';
import '../../data/models/post_model.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final PostRepository _postRepository;
  final CloudinaryService _cloudinaryService;
  StreamSubscription? _notificationSubscription;

  String _currentCategory = 'Tất cả';
  String? _currentSubject;
  String _currentUserId = '';
  final Map<String, int> _lastSeenCommentCounts = {};
  final Set<String> _knownPostIds = {};
  bool _isFirstFeedLoad = true;

  FeedCubit({
    required PostRepository postRepository,
    required CloudinaryService cloudinaryService,
  }) : _postRepository = postRepository,
       _cloudinaryService = cloudinaryService,
       super(FeedInitial());

  void updateCurrentUserId(String uid) {
    _currentUserId = uid;
  }

  Future<void> loadFeed({
    String? category,
    String? subjectCode,
    bool refresh = false,
  }) async {
    if (category != null) _currentCategory = category;
    _currentSubject = subjectCode;

    if (!refresh && state is! FeedLoaded) {
      emit(FeedLoading());
    }

    try {
      final result = await _postRepository.getFeedPostsPaged(
        category: _currentCategory,
        subjectCode: _currentSubject,
        lastDocument: null,
        limit: 15,
      );

      for (final post in result.items) {
        _knownPostIds.add(post.postId);
        _lastSeenCommentCounts[post.postId] = post.commentCount;
      }
      _isFirstFeedLoad = false;

      emit(
        FeedLoaded(
          posts: result.items,
          selectedCategory: _currentCategory,
          selectedSubject: _currentSubject,
          hasMore: result.hasMore,
          isLoadingMore: false,
          lastDocument: result.lastDocument,
        ),
      );

      _startNotificationListener();
    } catch (error) {
      emit(FeedError(error.toString()));
    }
  }

  Future<void> loadMorePosts() async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await _postRepository.getFeedPostsPaged(
        category: currentState.selectedCategory,
        subjectCode: currentState.selectedSubject,
        lastDocument: currentState.lastDocument,
        limit: 15,
      );

      final existingIds = currentState.posts.map((p) => p.postId).toSet();
      final newUniqueItems = result.items
          .where((p) => !existingIds.contains(p.postId))
          .toList();

      for (final post in newUniqueItems) {
        _knownPostIds.add(post.postId);
        _lastSeenCommentCounts[post.postId] = post.commentCount;
      }

      emit(
        currentState.copyWith(
          posts: [...currentState.posts, ...newUniqueItems],
          lastDocument: result.lastDocument,
          hasMore: result.hasMore && newUniqueItems.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _startNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _postRepository
        .getFeedPosts(category: _currentCategory, subjectCode: _currentSubject)
        .listen((posts) {
          if (!_isFirstFeedLoad && _currentUserId.isNotEmpty) {
            for (final post in posts) {
              // 1. Tag notification trigger
              if (!_knownPostIds.contains(post.postId) &&
                  post.authorId != _currentUserId &&
                  post.taggedUserIds.contains(_currentUserId)) {
                try {
                  if (sl.isRegistered<NotificationService>()) {
                    sl<NotificationService>().showNotification(
                      id: ('tag_${post.postId}').hashCode,
                      title: '${post.authorName} đã gắn thẻ bạn',
                      body:
                          'Trong bài viết: "${post.content.length > 50 ? '${post.content.substring(0, 50)}...' : post.content}"',
                      payload: 'post:${post.postId}',
                    );
                  }
                } catch (_) {}
              }

              // 2. New comment on relevant post trigger (author or tagged user)
              final isRelevant =
                  post.authorId == _currentUserId ||
                  post.taggedUserIds.contains(_currentUserId);
              if (isRelevant) {
                final prevCount = _lastSeenCommentCounts[post.postId];
                if (prevCount != null && post.commentCount > prevCount) {
                  final isAuthor = post.authorId == _currentUserId;
                  try {
                    if (sl.isRegistered<NotificationService>()) {
                      sl<NotificationService>().showNotification(
                        id: ('comment_${post.postId}').hashCode,
                        title: isAuthor
                            ? 'Bình luận mới trên bài viết của bạn'
                            : 'Bình luận mới trên bài viết bạn được gắn thẻ',
                        body:
                            'Bài viết "${post.content.length > 40 ? '${post.content.substring(0, 40)}...' : post.content}" có bình luận mới.',
                        payload: 'post:${post.postId}',
                      );
                    }
                  } catch (_) {}
                }
              }
            }
          }

          for (final post in posts) {
            _knownPostIds.add(post.postId);
            _lastSeenCommentCounts[post.postId] = post.commentCount;
          }
        }, onError: (_) {});
  }

  void filterByCategory(String category) {
    _currentCategory = category;
    loadFeed(category: _currentCategory, subjectCode: _currentSubject);
  }

  void filterBySubject(String? subjectCode) {
    _currentSubject = subjectCode;
    loadFeed(category: _currentCategory, subjectCode: _currentSubject);
  }

  Future<void> toggleLike(PostEntity post, String currentUserId) async {
    final isLiked = post.isLikedBy(currentUserId);

    // Optimistic UI update
    if (state is FeedLoaded) {
      final current = state as FeedLoaded;
      final updatedPosts = current.posts.map((p) {
        if (p.postId == post.postId) {
          final newLikedUsers = isLiked
              ? p.likedUsers.where((id) => id != currentUserId).toList()
              : [...p.likedUsers, currentUserId];
          final newCount = isLiked
              ? (p.likeCount > 0 ? p.likeCount - 1 : 0)
              : p.likeCount + 1;
          return p.copyWith(likedUsers: newLikedUsers, likeCount: newCount);
        }
        return p;
      }).toList();
      emit(current.copyWith(posts: updatedPosts));
    }

    try {
      await _postRepository.toggleLikePost(
        postId: post.postId,
        userId: currentUserId,
        isCurrentlyLiked: isLiked,
      );

      // Gửi thông báo trong ứng dụng khi bấm Thích (và không phải tự like bài mình)
      if (!isLiked && post.authorId.isNotEmpty && post.authorId != currentUserId) {
        try {
          if (sl.isRegistered<InAppNotificationRepository>()) {
            String currentUserName = 'Một người dùng';
            String currentUserAvatar = '';
            if (sl.isRegistered<AuthCubit>()) {
              final authState = sl<AuthCubit>().state;
              if (authState is Authenticated) {
                currentUserName = authState.user.displayName;
                currentUserAvatar = authState.user.avatarUrl;
              }
            }

            final contentSnippet = post.content.length > 70
                ? '${post.content.substring(0, 70)}...'
                : post.content;

            await sl<InAppNotificationRepository>().sendNotification(
              NotificationEntity(
                id: 'notif_like_${post.postId}_$currentUserId',
                userId: post.authorId,
                title: '$currentUserName đã thích bài viết của bạn',
                content: contentSnippet,
                type: NotificationType.social,
                senderName: currentUserName,
                senderAvatar: currentUserAvatar,
                createdAt: DateTime.now(),
                actionRoute: 'post_${post.postId}',
                extraData: {'postId': post.postId},
              ),
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Stream<List<CommentEntity>> getComments(String postId) {
    return _postRepository.getComments(postId);
  }

  Future<void> addComment({
    required String postId,
    String? commentId,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String authorStudentId,
    required String authorFaculty,
    required String content,
    String? replyToCommentId,
    String? replyToAuthorName,
    String? replyToAuthorId,
  }) async {
    final effectiveCommentId = (commentId != null && commentId.isNotEmpty)
        ? commentId
        : 'cmt_${DateTime.now().millisecondsSinceEpoch}_${authorId.hashCode.abs()}';

    final comment = CommentEntity(
      commentId: effectiveCommentId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorStudentId: authorStudentId,
      authorFaculty: authorFaculty,
      content: content,
      createdAt: DateTime.now(),
      replyToCommentId: replyToCommentId,
      replyToAuthorName: replyToAuthorName,
    );

    // Optimistic update of comment count in state
    if (state is FeedLoaded) {
      final current = state as FeedLoaded;
      final updatedPosts = current.posts.map((p) {
        if (p.postId == postId) {
          return p.copyWith(commentCount: p.commentCount + 1);
        }
        return p;
      }).toList();
      emit(current.copyWith(posts: updatedPosts));
    }

    await _postRepository.addComment(postId, comment);

    // Gửi thông báo trong ứng dụng cho bình luận và phản hồi
    try {
      if (sl.isRegistered<InAppNotificationRepository>()) {
        final notifRepo = sl<InAppNotificationRepository>();
        final contentSnippet = content.length > 70
            ? '${content.substring(0, 70)}...'
            : content;

        final isReply = replyToAuthorId != null &&
            replyToAuthorId.isNotEmpty &&
            replyToAuthorId != authorId;

        // 1. Gửi thông báo cho tác giả bài viết
        // Chỉ gửi thông báo bình luận nếu tác giả bài viết khác với người bình luận,
        // VÀ khác với người được trả lời (tránh gửi 2 thông báo cho cùng 1 người khi chủ post được reply)
        if (state is FeedLoaded) {
          final post = (state as FeedLoaded).posts
              .where((p) => p.postId == postId)
              .firstOrNull;
          if (post != null &&
              post.authorId.isNotEmpty &&
              post.authorId != authorId &&
              (!isReply || post.authorId != replyToAuthorId)) {
            await notifRepo.sendNotification(
              NotificationEntity(
                id: 'notif_cmt_${postId}_$effectiveCommentId',
                userId: post.authorId,
                title: '$authorName đã bình luận về bài viết của bạn',
                content: contentSnippet,
                type: NotificationType.social,
                senderName: authorName,
                senderAvatar: authorAvatar,
                createdAt: DateTime.now(),
                actionRoute: 'post_$postId',
                extraData: {'postId': postId, 'commentId': effectiveCommentId},
              ),
            );
          }
        }

        // 2. Gửi thông báo cho người được trả lời
        if (isReply) {
          await notifRepo.sendNotification(
            NotificationEntity(
              id: 'notif_reply_${postId}_$effectiveCommentId',
              userId: replyToAuthorId,
              title: '$authorName đã trả lời bình luận của bạn',
              content: contentSnippet,
              type: NotificationType.social,
              senderName: authorName,
              senderAvatar: authorAvatar,
              createdAt: DateTime.now(),
              actionRoute: 'post_$postId',
              extraData: {'postId': postId, 'commentId': effectiveCommentId},
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> sharePost({
    required PostEntity originalPost,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String authorStudentId,
    required String authorFaculty,
    required String caption,
  }) async {
    final newPostId =
        'post_share_${DateTime.now().millisecondsSinceEpoch}_${authorId.hashCode.abs()}';
    final newPost = PostModel(
      postId: newPostId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorStudentId: authorStudentId,
      authorFaculty: authorFaculty,
      content: caption,
      postType: 'share',
      category: 'Chia sẻ',
      createdAt: DateTime.now(),
      sharesCount: 0,
      sharedPostId: originalPost.postId,
      sharedPostAuthorName: originalPost.authorName,
      sharedPostAuthorAvatar: originalPost.authorAvatar,
      sharedPostContent: originalPost.content,
    );

    // Lưu bài viết chia sẻ mới vào collection
    await _postRepository.createPost(newPost);

    // Tăng số lượt chia sẻ trên bài viết gốc
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.postsCollection)
          .doc(originalPost.postId)
          .update({'sharesCount': FieldValue.increment(1)});
    } catch (_) {}

    // Gửi thông báo cho tác giả bài viết gốc
    if (originalPost.authorId.isNotEmpty && originalPost.authorId != authorId) {
      try {
        if (sl.isRegistered<InAppNotificationRepository>()) {
          await sl<InAppNotificationRepository>().sendNotification(
            NotificationEntity(
              id: 'notif_share_$newPostId',
              userId: originalPost.authorId,
              title: '$authorName đã chia sẻ bài viết của bạn',
              content: originalPost.content.length > 70
                  ? '${originalPost.content.substring(0, 70)}...'
                  : originalPost.content,
              type: NotificationType.social,
              senderName: authorName,
              senderAvatar: authorAvatar,
              createdAt: DateTime.now(),
              actionRoute: 'post_${originalPost.postId}',
              extraData: {'postId': originalPost.postId},
            ),
          );
        }
      } catch (_) {}
    }

    // Tải lại bảng tin
    await loadFeed();
  }

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String authorStudentId,
    required String authorFaculty,
    required String content,
    required String category,
    String? subjectCode,
    List<String> taggedUserIds = const [],
    Map<String, String> taggedUserNames = const {},
    List<File> imageFiles = const [],
    List<File> docFiles = const [],
  }) async {
    try {
      List<PostAttachment> attachments = [];

      for (final imgFile in imageFiles) {
        final url = await _cloudinaryService.uploadImage(imgFile);
        if (url != null) {
          attachments.add(
            PostAttachment(
              url: url,
              name: imgFile.path.split(Platform.pathSeparator).last,
              type: 'image',
            ),
          );
        }
      }

      for (final docFile in docFiles) {
        final url = await _cloudinaryService.uploadDocument(docFile);
        if (url != null) {
          final ext = docFile.path.split('.').last.toLowerCase();
          attachments.add(
            PostAttachment(
              url: url,
              name: docFile.path.split(Platform.pathSeparator).last,
              type: ext,
            ),
          );
        }
      }

      final newPost = PostEntity(
        postId: '',
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        authorStudentId: authorStudentId,
        authorFaculty: authorFaculty,
        content: content,
        postType: attachments.isEmpty
            ? 'text'
            : (attachments.any((a) => a.type == 'image')
                  ? 'image'
                  : 'document'),
        category: category,
        subjectCode: subjectCode?.trim().isEmpty == true
            ? null
            : subjectCode?.trim(),
        attachments: attachments,
        tags: _extractTags(content),
        taggedUserIds: taggedUserIds,
        taggedUserNames: taggedUserNames,
      );

      await _postRepository.createPost(newPost);
      // Reload first page to show newly created post at the top
      await loadFeed(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost({
    required String postId,
    required String content,
    required String category,
    String? subjectCode,
    List<String>? taggedUserIds,
    Map<String, String>? taggedUserNames,
    List<PostAttachment> existingAttachments = const [],
    List<File> newImageFiles = const [],
    List<File> newDocFiles = const [],
  }) async {
    try {
      List<PostAttachment> attachments = List.from(existingAttachments);

      for (final imgFile in newImageFiles) {
        final url = await _cloudinaryService.uploadImage(imgFile);
        if (url != null) {
          attachments.add(
            PostAttachment(
              url: url,
              name: imgFile.path.split(Platform.pathSeparator).last,
              type: 'image',
            ),
          );
        }
      }

      for (final docFile in newDocFiles) {
        final url = await _cloudinaryService.uploadDocument(docFile);
        if (url != null) {
          final ext = docFile.path.split('.').last.toLowerCase();
          attachments.add(
            PostAttachment(
              url: url,
              name: docFile.path.split(Platform.pathSeparator).last,
              type: ext,
            ),
          );
        }
      }

      final postType = attachments.isEmpty
          ? 'text'
          : (attachments.any((a) => a.type == 'image') ? 'image' : 'document');

      final updatedPost = PostEntity(
        postId: postId,
        authorId: '',
        authorName: '',
        content: content,
        postType: postType,
        category: category,
        subjectCode: subjectCode?.trim().isEmpty == true
            ? null
            : subjectCode?.trim(),
        attachments: attachments,
        tags: _extractTags(content),
        taggedUserIds: taggedUserIds ?? const [],
        taggedUserNames: taggedUserNames ?? const {},
      );

      await _postRepository.updatePost(updatedPost);

      if (state is FeedLoaded) {
        final current = state as FeedLoaded;
        final updatedPosts = current.posts.map((p) {
          if (p.postId == postId) {
            return p.copyWith(
              content: content,
              category: category,
              subjectCode: subjectCode?.trim().isEmpty == true
                  ? null
                  : subjectCode?.trim(),
              attachments: attachments,
              postType: postType,
              tags: _extractTags(content),
              taggedUserIds: taggedUserIds ?? p.taggedUserIds,
              taggedUserNames: taggedUserNames ?? p.taggedUserNames,
            );
          }
          return p;
        }).toList();
        emit(current.copyWith(posts: updatedPosts));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postRepository.deletePost(postId);
      if (state is FeedLoaded) {
        final current = state as FeedLoaded;
        emit(
          current.copyWith(
            posts: current.posts.where((p) => p.postId != postId).toList(),
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  List<String> _extractTags(String content) {
    final exp = RegExp(r'#(\w+)');
    final matches = exp.allMatches(content);
    return matches.map((m) => m.group(0)!).toList();
  }

  Future<void> toggleLikeComment({
    required String postId,
    required String commentId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      await _postRepository.toggleLikeComment(
        postId: postId,
        commentId: commentId,
        userId: userId,
        isCurrentlyLiked: isCurrentlyLiked,
      );
    } catch (_) {}
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await _postRepository.deleteComment(postId: postId, commentId: commentId);
      if (state is FeedLoaded) {
        final current = state as FeedLoaded;
        final updatedPosts = current.posts.map((p) {
          if (p.postId == postId) {
            final newCount = (p.commentCount > 0) ? p.commentCount - 1 : 0;
            return p.copyWith(commentCount: newCount);
          }
          return p;
        }).toList();
        emit(current.copyWith(posts: updatedPosts));
      }
    } catch (_) {}
  }

  Future<void> editComment({
    required String postId,
    required String commentId,
    required String newContent,
  }) async {
    try {
      await _postRepository.editComment(
        postId: postId,
        commentId: commentId,
        newContent: newContent,
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
