import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/datasources/phenikaa_student_directory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../../events/presentation/pages/events_page.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_bottom_sheet.dart';
import '../widgets/post_comments_bottom_sheet.dart';
import '../../../chat/presentation/pages/conversations_page.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _isSearching = false;
  int _searchTab = 0; // 0: Posts, 1: Students
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
    {'title': 'Học bổng K17', 'icon': Icons.school_rounded, 'type': 'blue', 'category': 'Học thuật'},
    {'title': 'Hội thao PU', 'icon': Icons.sports_soccer_rounded, 'type': 'orange', 'category': 'Thể thao'},
    {'title': 'Hackathon IT', 'icon': Icons.code_rounded, 'type': 'mint', 'category': 'Học thuật'},
    {'title': 'Acoustic Night', 'icon': Icons.music_note_rounded, 'type': 'violet', 'category': 'Văn nghệ'},
    {'title': 'CLB Tình nguyện', 'icon': Icons.volunteer_activism_rounded, 'type': 'coral', 'category': 'Tình nguyện'},
    {'title': 'Sự kiện PU', 'icon': Icons.celebration_rounded, 'type': 'blue', 'category': 'Tất cả'},
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedCubit>().loadFeed();
      }
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.notificationsSubcollection)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> displayNotifications = notifications;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    displayNotifications = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final sender = data['sender'] as String? ?? 'Trường ĐH Phenikaa';
                      final title = data['title'] as String? ?? '';
                      final content = data['content'] as String? ?? '';
                      final time = data['time'] as String? ?? 'Gần đây';
                      final isNew = data['isNew'] as bool? ?? false;

                      IconData icon = Icons.notifications_rounded;
                      Color color = AppTheme.primaryColor(context);

                      if (sender.contains('Đào tạo')) {
                        icon = Icons.calendar_month_rounded;
                        color = AppTheme.primaryColor(context);
                      } else if (sender.contains('Sinh viên') || sender.contains('Học bổng')) {
                        icon = Icons.military_tech_rounded;
                        color = AppTheme.accentColor(context);
                      } else if (sender.contains('Đoàn') || sender.contains('Hội')) {
                        icon = Icons.sports_basketball_rounded;
                        color = AppTheme.mintColor(context);
                      }

                      return {
                        'sender': sender,
                        'title': title,
                        'content': content,
                        'time': time,
                        'isNew': isNew,
                        'icon': icon,
                        'color': color,
                      };
                    }).toList();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayNotifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (_, index) {
                      final notif = displayNotifications[index];
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventsPage({String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsPage(initialCategory: category),
      ),
    );
  }

  Widget _buildStudentSearchResults(
    BuildContext context,
    String currentUserId,
    String currentUserName,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .snapshots(),
      builder: (context, snapshot) {
        final firestoreUsers = snapshot.data?.docs ?? [];
        final Map<String, Map<String, dynamic>> studentsMap = {};

        // 1. Static Phenikaa directory
        for (final s in PhenikaaStudentDirectory.defaultStudents) {
          studentsMap[s.studentId] = {
            'uid': s.studentId,
            'studentId': s.studentId,
            'name': s.fullName,
            'faculty': s.faculty,
            'major': s.major,
            'cohort': s.cohort,
            'avatar': '',
          };
        }

        // 2. Overlay with registered users
        for (final doc in firestoreUsers) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final stId = data['studentId'] as String? ?? '';
            final name = data['displayName'] as String? ?? '';
            final faculty = data['faculty'] as String? ?? '';
            final cohort = (data['cohort'] as num?)?.toInt() ?? 17;
            final avatar = data['avatarUrl'] as String? ?? '';

            final key = stId.isNotEmpty ? stId : doc.id;
            studentsMap[key] = {
              'uid': doc.id,
              'studentId': stId,
              'name': name.isNotEmpty ? name : (studentsMap[key]?['name'] ?? 'Sinh viên PU'),
              'faculty': faculty.isNotEmpty ? faculty : (studentsMap[key]?['faculty'] ?? ''),
              'major': studentsMap[key]?['major'] ?? '',
              'cohort': cohort,
              'avatar': avatar,
            };
          }
        }

        final allStudents = studentsMap.values.toList();
        final matched = allStudents.where((s) {
          if (query.isEmpty) return true;
          final name = (s['name'] as String).toLowerCase();
          final id = (s['studentId'] as String).toLowerCase();
          final fac = (s['faculty'] as String).toLowerCase();
          final maj = (s['major'] as String).toLowerCase();
          return name.contains(query) || id.contains(query) || fac.contains(query) || maj.contains(query);
        }).toList();

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
                      'Không tìm thấy sinh viên cho "$query"',
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
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final student = matched[index];
              final sUid = student['uid'] as String;
              final sName = student['name'] as String;
              final sId = student['studentId'] as String;
              final sFac = student['faculty'] as String;
              final sMajor = student['major'] as String;
              final sCohort = student['cohort'] as int;
              final sAvatar = student['avatar'] as String;
              final isSelf = currentUserId.isNotEmpty && (currentUserId == sUid || currentUserId == sId);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : AppTheme.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
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
                          sName.isNotEmpty ? sName.trim().split(' ').last[0].toUpperCase() : 'P',
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
                              Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryColor(context)),
                              if (sCohort > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
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
                              [if (sFac.isNotEmpty) sFac, if (sMajor.isNotEmpty) sMajor].join(' • '),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                                final convId = await context.read<ChatCubit>().startDirectChat(
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
                                        participantIds: [currentUserId, sUid]..sort(),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Không thể mở tin nhắn: $e')),
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
            },
            childCount: matched.length,
          ),
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
    final currentUserName = authState is Authenticated ? authState.user.displayName : 'Bạn';
    final currentUserStudentId = authState is Authenticated ? authState.user.studentId : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context) ? colorScheme.surfaceContainerHighest : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.isDark(context) ? Colors.white10 : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    cursorColor: AppTheme.oceanBlue,
                    decoration: InputDecoration(
                      hintText: _searchTab == 0 ? l10n.search_posts_hint : 'Tìm sinh viên theo Tên, MSSV...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      icon: Icon(Icons.search_rounded, size: 18, color: AppTheme.oceanBlue),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.oceanToOrangeGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                      ),
                      child: Image.asset(
                        'assets/logo/phenikaa_logo.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => Icon(Icons.school, color: AppTheme.primaryColor(context), size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.oceanToOrangeGradient.createShader(bounds),
                    child: const Text(
                      'PU Connection',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
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
                }
              });
            },
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(Icons.forum_outlined, color: colorScheme.onSurface),
                tooltip: 'Tin nhắn',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConversationsPage()),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface),
            tooltip: l10n.notifications,
            onPressed: () => _showNotificationsModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<FeedCubit>().loadFeed(),
        child: CustomScrollView(
          slivers: [
            if (_isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _searchTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _searchTab == 0 ? AppTheme.oceanGradient : null,
                                color: _searchTab == 0 ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _searchTab == 0
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.oceanBlue.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 16,
                                    color: _searchTab == 0 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bài viết',
                                    style: TextStyle(
                                      color: _searchTab == 0 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: _searchTab == 0 ? FontWeight.bold : FontWeight.w600,
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
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _searchTab == 1 ? AppTheme.oceanGradient : null,
                                color: _searchTab == 1 ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _searchTab == 1
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.oceanBlue.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                    color: _searchTab == 1 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sinh viên PU',
                                    style: TextStyle(
                                      color: _searchTab == 1 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: _searchTab == 1 ? FontWeight.bold : FontWeight.w600,
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
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  height: 94,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: _highlights.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = _highlights[index];
                      final color = _getHighlightColor(context, item['type'] as String);
                      return GestureDetector(
                        onTap: () => _openEventsPage(category: item['category'] as String?),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.oceanToOrangeGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface,
                                ),
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: color.withValues(alpha: 0.12),
                                  child: Icon(item['icon'] as IconData, color: color, size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 72,
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.85),
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.isDark(context)
                          ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                          : AppTheme.borderLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.isDark(context)
                            ? Colors.black.withValues(alpha: 0.25)
                            : const Color(0xFF0284C7).withValues(alpha: 0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.oceanToOrangeGradient,
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor(context),
                          ),
                          child: Center(
                            child: Text(
                              currentUserName.isNotEmpty ? currentUserName[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
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
                              color: AppTheme.isDark(context)
                                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                  : AppTheme.borderSubtle,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.create_post_hint,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                          foregroundColor: AppTheme.primaryColor(context),
                          minimumSize: const Size(38, 38),
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
                      height: 42,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filterCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _filterCategories[index];
                          final isSelected = cat == selectedCategory;

                          return GestureDetector(
                            onTap: () => context.read<FeedCubit>().filterByCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppTheme.oceanGradient : null,
                                color: isSelected ? null : colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.oceanBlue.withValues(alpha: 0.28),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.orangeAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    categoryMap[cat] ?? cat,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.onSurface.withValues(alpha: 0.8),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
              _buildStudentSearchResults(context, currentUserId, currentUserName)
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
                        final isOwner = (currentUserId.isNotEmpty && post.authorId == currentUserId) ||
                            (currentUserStudentId.isNotEmpty && post.authorStudentId == currentUserStudentId);

                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onLikePressed: () {
                            context.read<FeedCubit>().toggleLike(post, currentUserId);
                          },
                          onCommentPressed: () => _openCommentsModal(post),
                          onSharePressed: () {
                            Clipboard.setData(ClipboardData(text: '${post.authorName}: ${post.content}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép nội dung bài viết vào bộ nhớ tạm!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          onChatPressed: (!isOwner && post.authorId.isNotEmpty && currentUserId.isNotEmpty)
                              ? () async {
                                  try {
                                    final convId = await context.read<ChatCubit>().startDirectChat(
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
                                            otherUserFaculty: post.authorFaculty,
                                            participantIds: [currentUserId, post.authorId]..sort(),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Không thể mở cuộc trò chuyện: $e')),
                                      );
                                    }
                                  }
                                }
                              : null,
                          onEditPressed: isOwner ? () => _openEditPost(post) : null,
                          onDeletePressed: isOwner
                              ? () async {
                                  try {
                                    await context.read<FeedCubit>().deletePost(post.postId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.delete_post_success),
                                          backgroundColor: AppTheme.primaryColor(context),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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

