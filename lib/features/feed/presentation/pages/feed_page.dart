import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_bottom_sheet.dart';
import '../widgets/post_comments_bottom_sheet.dart';
import '../widgets/share_post_bottom_sheet.dart';
import '../../../chat/presentation/pages/conversations_page.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../chat/presentation/cubit/chat_state.dart';
import '../../../notifications/presentation/cubit/in_app_notifications_cubit.dart';
import '../../../notifications/presentation/cubit/in_app_notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notes/presentation/widgets/notes_feed_section.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _isSearching = false;
  int _searchTab = 0; // 0: Posts, 1: Students
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasSubmittedSearch = false;
  String _submittedQuery = '';

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _hasSubmittedSearch = false;
        _submittedQuery = '';
      });
      return;
    }
    setState(() {
      _hasSubmittedSearch = true;
      _submittedQuery = trimmed;
    });
  }

  final List<String> _filterCategories = [
    'Tất cả',
    'Tài liệu',
    'Hỏi bài',
    'Tìm nhóm',
    'Thảo luận',
    'Thông báo',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedCubit>().loadFeed();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      context.read<FeedCubit>().loadMorePosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

  void _openEditPost(PostEntity post) {
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
    NotificationsPage.showAsBottomSheet(context);
  }

  Widget _buildStudentSearchResults(
    BuildContext context,
    String currentUserId,
    String currentUserName,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    if (!_hasSubmittedSearch || _submittedQuery.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tìm kiếm sinh viên Phenikaa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập họ tên, mã sinh viên hoặc ngành học rồi bấm Tìm kiếm để tra cứu hồ sơ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final query = _submittedQuery.toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final firestoreUsers = snapshot.data?.docs ?? [];
        final List<Map<String, dynamic>> matched = [];

        for (final doc in firestoreUsers) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final stId = data['studentId'] as String? ?? '';
            final name = data['displayName'] as String? ?? '';
            final faculty = data['faculty'] as String? ?? '';
            final major = data['major'] as String? ?? '';
            final cohort = (data['cohort'] as num?)?.toInt() ?? 17;
            final avatar = data['avatarUrl'] as String? ?? '';

            if (name.toLowerCase().contains(query) ||
                stId.toLowerCase().contains(query) ||
                faculty.toLowerCase().contains(query) ||
                major.toLowerCase().contains(query)) {
              matched.add({
                'uid': doc.id,
                'studentId': stId,
                'name': name.isNotEmpty ? name : 'Sinh viên PU',
                'faculty': faculty,
                'major': major,
                'cohort': cohort,
                'avatar': avatar,
              });
            }
          }
        }

        if (matched.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 56,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy sinh viên cho "$_submittedQuery"',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử tìm theo Tên, MSSV hoặc Khoa chuyên ngành',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final student = matched[index];
            final sUid = student['uid'] as String;
            final sName = student['name'] as String;
            final sId = student['studentId'] as String;
            final sFac = student['faculty'] as String;
            final sMajor = student['major'] as String;
            final sCohort = student['cohort'] as int;
            final sAvatar = student['avatar'] as String;
            final isSelf =
                currentUserId.isNotEmpty &&
                (currentUserId == sUid || currentUserId == sId);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                      : AppTheme.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(
                            userId: sUid,
                            userName: sName,
                            studentId: sId,
                            faculty: sFac,
                            avatarUrl: sAvatar,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.blueContainer(context),
                      child: Text(
                        sName.isNotEmpty
                            ? sName.trim().split(' ').last[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                        userId: sUid,
                                        userName: sName,
                                        studentId: sId,
                                        faculty: sFac,
                                        avatarUrl: sAvatar,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  sName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppTheme.primaryColor(context),
                            ),
                            if (sCohort > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor(
                                    context,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'K$sCohort',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor(context),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sId.isNotEmpty ? 'MSSV: $sId' : 'Sinh viên Phenikaa',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (sFac.isNotEmpty || sMajor.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (sFac.isNotEmpty) sFac,
                              if (sMajor.isNotEmpty) sMajor,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.blueContainer(context),
                          foregroundColor: AppTheme.primaryColor(context),
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.person_rounded, size: 18),
                        tooltip: 'Hồ sơ',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                userId: sUid,
                                userName: sName,
                                studentId: sId,
                                faculty: sFac,
                                avatarUrl: sAvatar,
                              ),
                            ),
                          );
                        },
                      ),
                      if (!isSelf && currentUserId.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accentColor(context),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                          tooltip: 'Nhắn tin',
                          onPressed: () async {
                            try {
                              final convId = await context
                                  .read<ChatCubit>()
                                  .startDirectChat(
                                    currentUserId: currentUserId,
                                    currentUserName: currentUserName,
                                    otherUserId: sUid,
                                    otherUserName: sName,
                                    otherUserFaculty: sFac,
                                  );
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      conversationId: convId,
                                      otherUserId: sUid,
                                      otherUserName: sName,
                                      otherUserFaculty: sFac,
                                      participantIds: [currentUserId, sUid]
                                        ..sort(),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Không thể mở tin nhắn: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }, childCount: matched.length),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserName = authState is Authenticated
        ? authState.user.displayName
        : 'Bạn';
    final currentUserStudentId = authState is Authenticated
        ? authState.user.studentId
        : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context)
                      ? colorScheme.surfaceContainerHighest
                      : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.isDark(context)
                        ? Colors.white10
                        : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) => _performSearch(val),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    cursorColor: AppTheme.oceanBlue,
                    decoration: InputDecoration(
                      hintText: _searchTab == 0
                          ? l10n.search_posts_hint
                          : 'Tìm sinh viên theo Tên, MSSV...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.oceanBlue,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _hasSubmittedSearch = false;
                                  _submittedQuery = '';
                                });
                              },
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            color: AppTheme.oceanBlue,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Tìm kiếm',
                            onPressed: () => _performSearch(_searchController.text),
                          ),
                        ],
                      ),
                    ),
                    onChanged: (val) {
                      if (val.trim().isEmpty && _hasSubmittedSearch) {
                        setState(() {
                          _hasSubmittedSearch = false;
                          _submittedQuery = '';
                        });
                      } else {
                        setState(() {});
                      }
                    },
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      border: Border.all(
                        color: AppTheme.primaryColor(
                          context,
                        ).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/logo/phenikaa_logo.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.school_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PU Connection',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          color: AppTheme.isDark(context)
                              ? Colors.white
                              : AppTheme.deepBlue,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: colorScheme.onSurface,
            ),
            tooltip: _isSearching ? l10n.close : l10n.search,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchTab = 0;
                  _hasSubmittedSearch = false;
                  _submittedQuery = '';
                }
              });
            },
          ),
          if (!_isSearching) ...[
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, chatState) {
                final authUser = context.read<AuthCubit>().state is Authenticated
                    ? (context.read<AuthCubit>().state as Authenticated).user
                    : null;
                final currentUserId = authUser?.uid ?? '';
                final totalUnread = chatState.conversations.fold<int>(
                  0,
                  (total, conv) =>
                      total + (conv.unreadCounts[currentUserId] ?? 0),
                );

                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.forum_outlined,
                        color: colorScheme.onSurface,
                      ),
                      tooltip: 'Tin nhắn',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConversationsPage(),
                          ),
                        );
                      },
                    ),
                    if (totalUnread > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              totalUnread > 99 ? '99+' : '$totalUnread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            BlocBuilder<InAppNotificationsCubit, InAppNotificationsState>(
              builder: (context, notifState) {
                final unread = notifState.unreadCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        unread > 0
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                        color: unread > 0
                            ? AppTheme.accentColor(context)
                            : colorScheme.onSurface,
                      ),
                      tooltip: l10n.notifications,
                      onPressed: () => _showNotificationsModal(context),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor(context),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : unread.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<FeedCubit>().loadFeed(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (_isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest
                          : AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppTheme.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _searchTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _searchTab == 0
                                    ? AppTheme.primaryColor(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 16,
                                    color: _searchTab == 0
                                        ? Colors.white
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bài viết',
                                    style: TextStyle(
                                      color: _searchTab == 0
                                          ? Colors.white
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.7,
                                            ),
                                      fontWeight: _searchTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _searchTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _searchTab == 1
                                    ? AppTheme.primaryColor(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                    color: _searchTab == 1
                                        ? Colors.white
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sinh viên PU',
                                    style: TextStyle(
                                      color: _searchTab == 1
                                          ? Colors.white
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.7,
                                            ),
                                      fontWeight: _searchTab == 1
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isSearching) ...[
              const SliverToBoxAdapter(child: NotesFeedSection()),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.isDark(context)
                          ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                          : AppTheme.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.isDark(context)
                            ? Colors.black26
                            : const Color(0x08123B63),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: AppTheme.primaryColor(context),
                        child: Text(
                          currentUserName.isNotEmpty
                              ? currentUserName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openCreatePost,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.isDark(context)
                                  ? colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5)
                                  : AppTheme.borderSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : AppTheme.borderLight,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.create_post_hint,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.blueContainer(context),
                          foregroundColor: AppTheme.primaryColor(context),
                          minimumSize: const Size(38, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(Icons.image_outlined, size: 20),
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
                    final selectedCategory = state is FeedLoaded
                        ? state.selectedCategory
                        : 'Tất cả';

                    final categoryMap = {
                      'Tất cả': l10n.all_filter,
                      'Tài liệu': l10n.docs_filter,
                      'Hỏi bài': l10n.questions_filter,
                      'Tìm nhóm': l10n.groups_filter,
                      'Thảo luận': l10n.discussions_filter,
                      'Thông báo': l10n.announcements_filter,
                    };

                    return SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filterCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _filterCategories[index];
                          final isSelected = cat == selectedCategory;

                          return GestureDetector(
                            onTap: () =>
                                context.read<FeedCubit>().filterByCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor(context)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor(context)
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                  width: 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor(
                                            context,
                                          ).withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoryMap[cat] ?? cat,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.8,
                                            ),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
            ],
            if (_isSearching && _searchTab == 1)
              _buildStudentSearchResults(
                context,
                currentUserId,
                currentUserName,
              )
            else
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
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            Text('${l10n.error}: ${state.message}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<FeedCubit>().loadFeed(),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is FeedLoaded) {
                    if (_isSearching &&
                        (!_hasSubmittedSearch || _submittedQuery.isEmpty)) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.manage_search_rounded,
                                  size: 64,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tìm kiếm bài viết trên PU Connection',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhập từ khóa theo nội dung, mã môn, khoa, tác giả hoặc hashtag và bấm Tìm kiếm.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final query = _isSearching
                        ? _submittedQuery.toLowerCase()
                        : _searchController.text.trim().toLowerCase();
                    final displayedPosts = state.posts.where((post) {
                      if (query.isEmpty) return true;
                      final matchesContent = post.content
                          .toLowerCase()
                          .contains(query);
                      final matchesSubject =
                          post.subjectCode?.toLowerCase().contains(query) ??
                          false;
                      final matchesAuthor = post.authorName
                          .toLowerCase()
                          .contains(query);
                      final matchesTag = post.tags.any(
                        (t) => t.toLowerCase().contains(query),
                      );
                      return matchesContent ||
                          matchesSubject ||
                          matchesAuthor ||
                          matchesTag;
                    }).toList();

                    if (displayedPosts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSearching
                                    ? Icons.search_off_rounded
                                    : Icons.feed_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isSearching
                                    ? 'Không tìm thấy bài viết nào phù hợp với "$_submittedQuery"'
                                    : (query.isNotEmpty
                                        ? '${l10n.no_posts_found} "$query"'
                                        : l10n.no_posts_empty),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                              if (!_isSearching) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _openCreatePost,
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.create_post_title),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = displayedPosts[index];
                        final isOwner =
                            (currentUserId.isNotEmpty &&
                                post.authorId == currentUserId) ||
                            (currentUserStudentId.isNotEmpty &&
                                post.authorStudentId == currentUserStudentId);

                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onLikePressed: () {
                            context.read<FeedCubit>().toggleLike(
                              post,
                              currentUserId,
                            );
                          },
                          onCommentPressed: () => _openCommentsModal(post),
                          onSharePressed: () {
                            final authUser = context.read<AuthCubit>().state is Authenticated
                                ? (context.read<AuthCubit>().state as Authenticated).user
                                : null;
                            if (authUser != null) {
                              SharePostBottomSheet.show(
                                context,
                                post: post,
                                currentUser: authUser,
                              );
                            } else {
                              Clipboard.setData(
                                ClipboardData(
                                  text: '${post.authorName}: ${post.content}',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã sao chép nội dung bài viết vào bộ nhớ tạm!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          onChatPressed:
                              (!isOwner &&
                                  post.authorId.isNotEmpty &&
                                  currentUserId.isNotEmpty)
                              ? () async {
                                  try {
                                    final convId = await context
                                        .read<ChatCubit>()
                                        .startDirectChat(
                                          currentUserId: currentUserId,
                                          currentUserName: currentUserName,
                                          otherUserId: post.authorId,
                                          otherUserName: post.authorName,
                                          otherUserFaculty: post.authorFaculty,
                                        );
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatDetailPage(
                                            conversationId: convId,
                                            otherUserId: post.authorId,
                                            otherUserName: post.authorName,
                                            otherUserFaculty:
                                                post.authorFaculty,
                                            participantIds: [
                                              currentUserId,
                                              post.authorId,
                                            ]..sort(),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Không thể mở cuộc trò chuyện: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          onEditPressed: isOwner
                              ? () => _openEditPost(post)
                              : null,
                          onDeletePressed: isOwner
                              ? () async {
                                  try {
                                    await context.read<FeedCubit>().deletePost(
                                      post.postId,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.delete_post_success,
                                          ),
                                          backgroundColor:
                                              AppTheme.primaryColor(context),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('${l10n.error}: $e'),
                                          backgroundColor: Colors.red.shade700,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                        );
                      }, childCount: displayedPosts.length),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            BlocBuilder<FeedCubit, FeedState>(
              builder: (context, state) {
                if (state is FeedLoaded) {
                  if (state.isLoadingMore) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    );
                  }
                  if (!state.hasMore && state.posts.length >= 10) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bạn đã xem hết bài viết',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
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
