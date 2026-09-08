import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final PostRepository _postRepository;
  final CloudinaryService _cloudinaryService;
  StreamSubscription? _feedSubscription;

  String _currentCategory = 'Tất cả';
  String? _currentSubject;

  FeedCubit({
    required PostRepository postRepository,
    required CloudinaryService cloudinaryService,
  })  : _postRepository = postRepository,
        _cloudinaryService = cloudinaryService,
        super(FeedInitial());

  void loadFeed({String? category, String? subjectCode}) {
    if (category != null) _currentCategory = category;
    _currentSubject = subjectCode;

    emit(FeedLoading());
    _feedSubscription?.cancel();
    _feedSubscription = _postRepository
        .getFeedPosts(
          category: _currentCategory,
          subjectCode: _currentSubject,
        )
        .listen(
          (posts) {
            emit(FeedLoaded(
              posts: posts,
              selectedCategory: _currentCategory,
              selectedSubject: _currentSubject,
            ));
          },
          onError: (error) {
            emit(FeedError(error.toString()));
          },
        );
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
    try {
      await _postRepository.toggleLikePost(
        postId: post.postId,
        userId: currentUserId,
        isCurrentlyLiked: isLiked,
      );
    } catch (_) {
      // Revert if error
    }
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
    List<File> imageFiles = const [],
    List<File> docFiles = const [],
  }) async {
    try {
      List<PostAttachment> attachments = [];

      // 1. Upload ảnh lên Cloudinary miễn phí nếu có
      for (final imgFile in imageFiles) {
        final url = await _cloudinaryService.uploadImage(imgFile);
        if (url != null) {
          attachments.add(PostAttachment(
            url: url,
            name: imgFile.path.split(Platform.pathSeparator).last,
            type: 'image',
          ));
        }
      }

      // 2. Upload tài liệu (PDF, Word) lên Cloudinary miễn phí nếu có
      for (final docFile in docFiles) {
        final url = await _cloudinaryService.uploadDocument(docFile);
        if (url != null) {
          attachments.add(PostAttachment(
            url: url,
            name: docFile.path.split(Platform.pathSeparator).last,
            type: docFile.path.endsWith('.pdf') ? 'pdf' : 'docx',
          ));
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
            : (attachments.any((a) => a.type == 'image') ? 'image' : 'document'),
        category: category,
        subjectCode: subjectCode?.trim().isEmpty == true ? null : subjectCode?.trim(),
        attachments: attachments,
        tags: _extractTags(content),
      );

      await _postRepository.createPost(newPost);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> seedMockData(String uid, String name) async {
    await _postRepository.seedMockPostsIfEmpty(uid, name);
  }

  List<String> _extractTags(String content) {
    final exp = RegExp(r'#(\w+)');
    final matches = exp.allMatches(content);
    return matches.map((m) => m.group(0)!).toList();
  }

  @override
  Future<void> close() {
    _feedSubscription?.cancel();
    return super.close();
  }
}
