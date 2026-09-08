import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_bottom_sheet.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<String> _filterCategories = [
    'Tất cả',
    'Tài liệu',
    'Hỏi bài',
    'Tìm nhóm',
    'Thảo luận',
    'Thông báo',
  ];

  final List<Map<String, dynamic>> _highlights = [
    {'title': 'Học bổng K17', 'icon': Icons.school_rounded, 'type': 'blue'},
    {'title': 'Hội thao PU', 'icon': Icons.sports_soccer_rounded, 'type': 'orange'},
    {'title': 'Hackathon IT', 'icon': Icons.code_rounded, 'type': 'mint'},
    {'title': 'Acoustic Night', 'icon': Icons.music_note_rounded, 'type': 'violet'},
    {'title': 'CLB Tình nguyện', 'icon': Icons.volunteer_activism_rounded, 'type': 'coral'},
  ];

  Color _getHighlightColor(BuildContext context, String type) {
    switch (type) {
      case 'orange':
        return AppTheme.accentColor(context);
      case 'mint':
        return AppTheme.mintColor(context);
      case 'violet':
        return AppTheme.violetColor(context);
      case 'coral':
        return AppTheme.coralColor(context);
      case 'blue':
      default:
        return AppTheme.primaryColor(context);
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    String uid = '';
    String name = 'Sinh viên Phenikaa';
    if (authState is Authenticated) {
      uid = authState.user.uid;
      name = authState.user.displayName;
    }

    final feedCubit = context.read<FeedCubit>();
    feedCubit.seedMockData(uid, name).then((_) {
      feedCubit.loadFeed();
    });
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FeedCubit>(),
        child: const CreatePostBottomSheet(),
      ),
    );
  }

  void _showHighlightModal(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: AppTheme.accentColor(context), size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sự kiện và tin tức tiêu biểu của trường Đại học Phenikaa đang diễn ra sôi nổi. Hãy theo dõi bảng tin và tham gia ngay cùng bạn bè!',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserName = authState is Authenticated ? authState.user.displayName : 'Bạn';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo/phenikaa_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 8),
            const Text(
              'PU Connection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tìm kiếm bài viết: Nhập từ khóa tại thanh tìm kiếm.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không có thông báo mới từ trường.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: AppTheme.orangeAccent,
        child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<FeedCubit>().loadFeed(),
        child: CustomScrollView(
          slivers: [
            // Campus Highlights Story Strip
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                height: 90,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: _highlights.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = _highlights[index];
                    final color = _getHighlightColor(context, item['type'] as String);
                    return GestureDetector(
                      onTap: () => _showHighlightModal(item['title'] as String),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.6)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: colorScheme.surface,
                              child: Icon(item['icon'] as IconData, color: color, size: 26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 68,
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Quick Post Creation Bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.isDark(context)
                          ? AppTheme.darkBlueContainer
                          : AppTheme.primaryBlue,
                      child: Text(
                        currentUserName.isNotEmpty ? currentUserName[0].toUpperCase() : 'P',
                        style: TextStyle(
                          color: AppTheme.isDark(context) ? AppTheme.darkPrimaryBlue : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openCreatePost,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            '$currentUserName ơi, chia sẻ tài liệu hoặc hỏi bài nhé?',
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: AppTheme.primaryColor(context)),
                      tooltip: 'Đính kèm ảnh',
                      onPressed: _openCreatePost,
                    ),
                  ],
                ),
              ),
            ),
            // Category Filter Chips
            SliverToBoxAdapter(
              child: BlocBuilder<FeedCubit, FeedState>(
                builder: (context, state) {
                  final selectedCategory = state is FeedLoaded ? state.selectedCategory : 'Tất cả';

                  return SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _filterCategories[index];
                        final isSelected = cat == selectedCategory;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor(context),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (AppTheme.isDark(context) ? Colors.black87 : Colors.white)
                                : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              context.read<FeedCubit>().filterByCategory(cat);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            // Feed Post List
            BlocBuilder<FeedCubit, FeedState>(
              builder: (context, state) {
                if (state is FeedLoading) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is FeedError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text('Lỗi: ${state.message}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<FeedCubit>().loadFeed(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is FeedLoaded) {
                  if (state.posts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có bài viết nào trong danh mục "${state.selectedCategory}"',
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openCreatePost,
                              icon: const Icon(Icons.add),
                              label: const Text('Đăng bài đầu tiên'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = state.posts[index];
                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onLikePressed: () {
                            context.read<FeedCubit>().toggleLike(post, currentUserId);
                          },
                          onCommentPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bình luận bài viết: Hãy để lại ý kiến của bạn.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                      childCount: state.posts.length,
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

