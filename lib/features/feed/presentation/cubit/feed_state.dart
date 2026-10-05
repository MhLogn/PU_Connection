import 'package:equatable/equatable.dart';
import '../../domain/entities/post_entity.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<PostEntity> posts;
  final String selectedCategory;
  final String? selectedSubject;
  final bool hasMore;
  final bool isLoadingMore;
  final dynamic lastDocument;

  const FeedLoaded({
    required this.posts,
    this.selectedCategory = 'Tất cả',
    this.selectedSubject,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  FeedLoaded copyWith({
    List<PostEntity>? posts,
    String? selectedCategory,
    String? selectedSubject,
    bool? hasMore,
    bool? isLoadingMore,
    dynamic lastDocument,
    bool clearLastDocument = false,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: clearLastDocument ? null : (lastDocument ?? this.lastDocument),
    );
  }

  @override
  List<Object?> get props => [
        posts,
        selectedCategory,
        selectedSubject,
        hasMore,
        isLoadingMore,
        lastDocument,
      ];
}

class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object?> get props => [message];
}
