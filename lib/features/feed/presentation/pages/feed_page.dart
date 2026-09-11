import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_bottom_sheet.dart';
import '../widgets/post_comments_bottom_sheet.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openCommentsModal(PostEntity post) {
    final authState = context.read<AuthCubit>().state;
    String uid = '';
    String name = 'Sinh viên Phenikaa';
    String avatar = '';
    String studentId = '';
    String faculty = '';

    if (authState is Authenticated) {
      uid = authState.user.uid;
      name = authState.user.displayName;
      avatar = authState.user.avatarUrl;
      studentId = authState.user.studentId;
      faculty = authState.user.faculty;
    }

    PostCommentsBottomSheet.show(
      context,
      post: post,
      currentUserId: uid,
      currentUserName: name,
      currentUserAvatar: avatar,
      currentUserStudentId: studentId,
      currentUserFaculty: faculty,
    );
  }

  void _showNotificationsModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifications = [
      {
        'sender': 'Phòng Đào tạo',
        'title': 'Đăng ký học phần HK2 (2025-2026)',
        'content': 'Hệ thống mở cổng đăng ký tín chỉ đợt 1 từ ngày 15/09 cho sinh viên K16, K17. Sinh viên lưu ý hoàn tất đóng học phí đúng hạn.',
        'time': '2 giờ trước',
        'isNew': true,
        'icon': Icons.calendar_month_rounded,
        'color': AppTheme.primaryColor(context),
      },
      {
        'sender': 'Phòng Công tác Sinh viên',
        'title': 'Xét Học bổng Khuyến khích Học tập Kỳ 1',
        'content': 'Công bố danh sách dự kiến sinh viên đạt học bổng Xuất sắc và Giỏi. Thời gian phản hồi đến hết ngày 18/09.',
        'time': '1 ngày trước',
        'isNew': true,
        'icon': Icons.military_tech_rounded,
        'color': AppTheme.accentColor(context),
      },
      {
        'sender': 'Đoàn Thanh Niên Phenikaa',
        'title': 'Khai mạc Hội thao Phenikaa Youth Games 2026',
        'content': 'Hội thao toàn trường với 6 môn thi đấu chính thức. Đăng ký tham gia tại văn phòng Đoàn Tòa A9.',
        'time': '2 ngày trước',
        'isNew': false,
        'icon': Icons.sports_basketball_rounded,
        'color': AppTheme.mintColor(context),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: AppTheme.accentColor(context), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Thông Báo Trường Phenikaa',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (_, index) {
                  final notif = notifications[index];
                  final isNew = notif['isNew'] as bool;
                  final color = notif['color'] as Color;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(notif['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif['sender'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (isNew) ...[
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor(context),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      notif['time'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['title'] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['content'] as String,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.onSurface.withValues(alpha: 0.75),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserName = authState is Authenticated ? authState.user.displayName : 'Bạn';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: l10n.search_posts_hint,
                  hintStyle: const TextStyle(color: Colors.white70, fontSize: 13.5),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Row(
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
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
            tooltip: _isSearching ? l10n.close : l10n.search,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            tooltip: l10n.notifications,
            onPressed: () => _showNotificationsModal(context),
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
                            l10n.create_post_hint,
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: AppTheme.primaryColor(context)),
                      tooltip: l10n.attach_image,
                      onPressed: _openCreatePost,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<FeedCubit, FeedState>(
                builder: (context, state) {
                  final selectedCategory = state is FeedLoaded ? state.selectedCategory : 'Tất cả';

                  final categoryMap = {
                    'Tất cả': l10n.all_filter,
                    'Tài liệu': l10n.docs_filter,
                    'Hỏi bài': l10n.questions_filter,
                    'Tìm nhóm': l10n.groups_filter,
                    'Thảo luận': l10n.discussions_filter,
                    'Thông báo': l10n.announcements_filter,
                  };

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
                          label: Text(categoryMap[cat] ?? cat),
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
                          Text('${l10n.error}: ${state.message}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<FeedCubit>().loadFeed(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is FeedLoaded) {
                  final query = _searchController.text.trim().toLowerCase();
                  final displayedPosts = state.posts.where((post) {
                    if (query.isEmpty) return true;
                    final matchesContent = post.content.toLowerCase().contains(query);
                    final matchesSubject = post.subjectCode?.toLowerCase().contains(query) ?? false;
                    final matchesAuthor = post.authorName.toLowerCase().contains(query);
                    final matchesTag = post.tags.any((t) => t.toLowerCase().contains(query));
                    return matchesContent || matchesSubject || matchesAuthor || matchesTag;
                  }).toList();

                  if (displayedPosts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty
                                  ? '${l10n.no_posts_found} "$query"'
                                  : l10n.no_posts_empty,
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openCreatePost,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.create_post_title),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = displayedPosts[index];
                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onLikePressed: () {
                            context.read<FeedCubit>().toggleLike(post, currentUserId);
                          },
                          onCommentPressed: () => _openCommentsModal(post),
                        );
                      },
                      childCount: displayedPosts.length,
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

