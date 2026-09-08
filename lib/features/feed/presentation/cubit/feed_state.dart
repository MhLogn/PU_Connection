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

  const FeedLoaded({
    required this.posts,
    this.selectedCategory = 'Tất cả',
    this.selectedSubject,
  });

  @override
  List<Object?> get props => [posts, selectedCategory, selectedSubject];
}

class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object?> get props => [message];
}
