import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../feed/presentation/cubit/feed_state.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/widgets/create_post_bottom_sheet.dart';
import '../../../feed/presentation/widgets/post_comments_bottom_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/saved_posts_cubit.dart';
import '../cubit/saved_posts_state.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final authState = context.watch<AuthCubit>().state;
    String currentUserId = '';
    String currentUserName = 'Sinh viên Phenikaa';
    String currentUserAvatar = '';
    String currentUserStudentId = '';
    String currentUserFaculty = '';

    if (authState is Authenticated) {
      currentUserId = authState.user.uid;
      currentUserName = authState.user.displayName;
      currentUserAvatar = authState.user.avatarUrl;
      currentUserStudentId = authState.user.studentId;
      currentUserFaculty = authState.user.faculty;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Bài viết đã lưu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocListener<SavedPostsCubit, SavedPostsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colorScheme.error,
              ),
            );
            context.read<SavedPostsCubit>().clearMessage();
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
            context.read<SavedPostsCubit>().clearMessage();
          }
        },
        child: BlocBuilder<SavedPostsCubit, SavedPostsState>(
          builder: (context, savedState) {
            final savedIds = savedState.savedPostIds;

            return BlocBuilder<FeedCubit, FeedState>(
              builder: (context, feedState) {
                final allPosts = feedState is FeedLoaded
                    ? feedState.posts
                    : <PostEntity>[];

                // Lọc các bài viết nằm trong savedIds
                final savedPosts = allPosts
                    .where((post) => savedIds.contains(post.postId))
                    .toList();

                if (savedPosts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              size: 42,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bài viết nào được lưu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy nhấn vào biểu tượng dấu trang ở góc dưới mỗi bài viết để lưu lại các bài học, tài liệu hay khi ôn thi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: savedPosts.length,
                  itemBuilder: (context, index) {
                    final post = savedPosts[index];
                    final isAuthor = post.authorId == currentUserId;

                    return PostCard(
                      post: post,
                      currentUserId: currentUserId,
                      onLikePressed: () => context.read<FeedCubit>().toggleLike(post, currentUserId),
                      onCommentPressed: () {
                        PostCommentsBottomSheet.show(
                          context,
                          post: post,
                          currentUserId: currentUserId,
                          currentUserName: currentUserName,
                          currentUserAvatar: currentUserAvatar,
                          currentUserStudentId: currentUserStudentId,
                          currentUserFaculty: currentUserFaculty,
                        );
                      },
                      onEditPressed: isAuthor
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => BlocProvider.value(
                                  value: context.read<FeedCubit>(),
                                  child: CreatePostBottomSheet(postToEdit: post),
                                ),
                              );
                            }
                          : null,
                      onDeletePressed: isAuthor
                          ? () {
                              context.read<FeedCubit>().deletePost(post.postId);
                            }
                          : null,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
