import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/phenikaa_student_directory.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../feed/presentation/widgets/create_post_bottom_sheet.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/widgets/post_comments_bottom_sheet.dart';
import '../../../documents/data/models/document_model.dart';
import '../../../documents/presentation/widgets/document_card.dart';
import '../../../friends/domain/entities/friendship_status.dart';
import '../../../friends/presentation/cubit/friendship_cubit.dart';
import '../../../friends/presentation/cubit/friendship_state.dart';
import '../../../friends/presentation/pages/friend_requests_page.dart';
import '../../../moderation/domain/entities/blocked_user_entity.dart';
import '../../../moderation/domain/entities/report_target_type.dart';
import '../../../moderation/presentation/cubit/moderation_cubit.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String studentId;
  final String faculty;
  final String avatarUrl;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.studentId = '',
    this.faculty = '',
    this.avatarUrl = '',
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final currentUid = authState.user.uid;
        context.read<FriendshipCubit>().initRelationship(
              currentUserId: currentUid,
              targetUserId: widget.userId,
            );
        if (currentUid == widget.userId) {
          context.read<FriendshipCubit>().initReceivedRequests(currentUid);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.uid;
    final currentUserName = authState.user.displayName.isNotEmpty
        ? authState.user.displayName
        : 'Sinh viên Phenikaa';
    final currentUserAvatar = authState.user.avatarUrl;
    final currentUserFaculty = authState.user.faculty;

    if (widget.userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tự nhắn tin cho chính mình!')),
      );
      return;
    }

    try {
      final convId = await context.read<ChatCubit>().startDirectChat(
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            currentUserAvatar: currentUserAvatar,
            currentUserFaculty: currentUserFaculty,
            otherUserId: widget.userId,
            otherUserName: widget.userName,
            otherUserFaculty: widget.faculty,
            otherUserAvatar: widget.avatarUrl,
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: convId,
              otherUserId: widget.userId,
              otherUserName: widget.userName,
              otherUserAvatar: widget.avatarUrl,
              otherUserFaculty: widget.faculty,
              participantIds: [currentUserId, widget.userId]..sort(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở cuộc trò chuyện: $e')),
        );
      }
    }
  }

  void _handleFriendAction({
    required BuildContext context,
    required FriendshipStatus status,
    required UserEntity currentUser,
    required UserEntity targetUser,
  }) {
    final cubit = context.read<FriendshipCubit>();

    switch (status) {
      case FriendshipStatus.none:
        cubit.sendFriendRequest(
          currentUserId: currentUser.uid,
          currentUserName: currentUser.displayName,
          currentUserAvatar: currentUser.avatarUrl,
          currentUserFaculty: currentUser.faculty,
          targetUserId: targetUser.uid,
          targetUserName: targetUser.displayName,
        );
        break;

      case FriendshipStatus.requestSent:
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hủy lời mời kết bạn?'),
            content: Text('Bạn có chắc chắn muốn hủy lời mời kết bạn gửi đến ${targetUser.displayName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bỏ qua'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  cubit.cancelFriendRequest(
                    currentUserId: currentUser.uid,
                    targetUserId: targetUser.uid,
                  );
                },
                child: const Text('Hủy lời mời'),
              ),
            ],
          ),
        );
        break;

      case FriendshipStatus.requestReceived:
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lời mời kết bạn từ ${targetUser.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Chấp nhận kết bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(ctx);
                      cubit.acceptFriendRequest(
                        currentUserId: currentUser.uid,
                        currentUserName: currentUser.displayName,
                        currentUserAvatar: currentUser.avatarUrl,
                        currentUserFaculty: currentUser.faculty,
                        senderId: targetUser.uid,
                        senderName: targetUser.displayName,
                        senderAvatar: targetUser.avatarUrl,
                        senderFaculty: targetUser.faculty,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.close_rounded, color: Colors.red),
                    title: const Text('Từ chối lời mời'),
                    onTap: () {
                      Navigator.pop(ctx);
                      cubit.declineFriendRequest(
                        currentUserId: currentUser.uid,
                        senderId: targetUser.uid,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case FriendshipStatus.friends:
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hủy kết bạn?'),
            content: Text('Bạn có chắc chắn muốn hủy kết bạn với ${targetUser.displayName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy bỏ'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(ctx);
                  cubit.unfriend(
                    currentUserId: currentUser.uid,
                    friendId: targetUser.uid,
                  );
                },
                child: const Text('Hủy kết bạn'),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final currentUid = currentUser?.uid ?? '';
    final isSelf = currentUid.isNotEmpty && currentUid == widget.userId;

    return BlocListener<FriendshipCubit, FriendshipState>(
      listener: (context, fState) {
        if (fState.message != null && fState.actionStatus == FriendshipActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fState.message!),
              backgroundColor: AppTheme.primaryColor(context),
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<FriendshipCubit>().clearMessage();
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.userId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection(FirebaseConstants.usersCollection)
                .doc(widget.userId)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          UserEntity user;
          if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
            user = UserModel.fromFirestore(snapshot.data!);
          } else {
            String finalName = widget.userName.isNotEmpty ? widget.userName : 'Sinh viên Phenikaa';
            String finalStudentId = widget.studentId;
            String finalFaculty = widget.faculty.isNotEmpty ? widget.faculty : 'Công nghệ thông tin';
            String finalMajor = 'Kỹ thuật phần mềm';
            int finalCohort = 17;

            final match = PhenikaaStudentDirectory.defaultStudents.where(
              (s) =>
                  s.fullName.toLowerCase() == finalName.toLowerCase() ||
                  (finalStudentId.isNotEmpty && s.studentId == finalStudentId),
            );
            if (match.isNotEmpty) {
              finalName = match.first.fullName;
              finalStudentId = match.first.studentId;
              finalFaculty = match.first.faculty;
              finalMajor = match.first.major;
              finalCohort = match.first.cohort;
            }

            user = UserModel(
              uid: widget.userId,
              email: '$finalStudentId@st.phenikaa-uni.edu.vn',
              studentId: finalStudentId,
              displayName: finalName,
              username: finalStudentId,
              faculty: finalFaculty,
              major: finalMajor,
              cohort: finalCohort,
              userType: 'student',
              avatarUrl: widget.avatarUrl,
              isVerified: true,
            );
          }

          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: Text(user.displayName),
              actions: [
                if (isSelf)
                  BlocBuilder<FriendshipCubit, FriendshipState>(
                    builder: (context, fState) {
                      final reqCount = fState.receivedRequests.length;
                      return Badge(
                        isLabelVisible: reqCount > 0,
                        label: Text('$reqCount'),
                        child: IconButton(
                          icon: const Icon(Icons.people_outline_rounded),
                          tooltip: 'Lời mời kết bạn',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FriendRequestsPage(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Chia sẻ hồ sơ',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã sao chép liên kết hồ sơ của ${user.displayName}!')),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'report') {
                        ReportBottomSheet.show(
                          context,
                          targetId: user.uid,
                          targetType: ReportTargetType.user,
                          targetAuthorId: user.uid,
                          targetAuthorName: user.displayName,
                        );
                      } else if (value == 'block') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Chặn người dùng này?'),
                            content: Text(
                              'Bạn sẽ không còn nhìn thấy bài viết, bình luận và không thể nhắn tin với ${user.displayName}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<ModerationCubit>().blockUser(
                                        currentUserId: currentUid,
                                        blockedUser: BlockedUserEntity(
                                          userId: user.uid,
                                          userName: user.displayName,
                                          userAvatar: user.avatarUrl,
                                          userFaculty: user.faculty,
                                          blockedAt: DateTime.now(),
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                                child: const Text('Chặn'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report_problem_outlined, color: Colors.orange, size: 20),
                            SizedBox(width: 10),
                            Text('Báo cáo người dùng'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text('Chặn người dùng này', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Digital Student Card
                        _buildDigitalCard(context, user),
                        const SizedBox(height: 16),

                        // Action buttons: Nhắn tin, Kết bạn, Theo dõi
                        if (!isSelf && currentUser != null) ...[
                          _buildActionButtons(context, currentUser, user),
                          const SizedBox(height: 16),
                        ],

                        // Metric counts: Posts, Friends, Followers, Following
                        _buildMetricsRow(context, user),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor(context),
                      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                      indicatorColor: AppTheme.primaryColor(context),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(icon: Icon(Icons.article_outlined), text: 'Bài viết'),
                        Tab(icon: Icon(Icons.people_alt_outlined), text: 'Bạn bè'),
                        Tab(icon: Icon(Icons.menu_book_outlined), text: 'Tài liệu'),
                        Tab(icon: Icon(Icons.info_outline_rounded), text: 'Thông tin'),
                      ],
                    ),
                    colorScheme.surface,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(context, user, currentUid),
                  _buildFriendsTab(context),
                  _buildDocumentsTab(context, user),
                  _buildAboutTab(context, user),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    UserEntity currentUser,
    UserEntity targetUser,
  ) {
    return BlocBuilder<FriendshipCubit, FriendshipState>(
      builder: (context, fState) {
        final rel = fState.relationship;
        final status = rel.friendshipStatus;
        final isFollowing = rel.isFollowing;

        // Button visuals according to friendship status
        String friendButtonText;
        IconData friendButtonIcon;
        Color friendButtonColor;

        switch (status) {
          case FriendshipStatus.none:
            friendButtonText = 'Kết bạn';
            friendButtonIcon = Icons.person_add_rounded;
            friendButtonColor = AppTheme.primaryColor(context);
            break;
          case FriendshipStatus.requestSent:
            friendButtonText = 'Đã gửi lời mời';
            friendButtonIcon = Icons.schedule_send_rounded;
            friendButtonColor = Colors.orange;
            break;
          case FriendshipStatus.requestReceived:
            friendButtonText = 'Phản hồi';
            friendButtonIcon = Icons.mark_email_unread_rounded;
            friendButtonColor = Colors.green;
            break;
          case FriendshipStatus.friends:
            friendButtonText = 'Bạn bè';
            friendButtonIcon = Icons.check_circle_rounded;
            friendButtonColor = AppTheme.mintColor(context);
            break;
        }

        return Column(
          children: [
            Row(
              children: [
                // Button 1: Nhắn tin
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                    label: const Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: Kết bạn
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleFriendAction(
                      context: context,
                      status: status,
                      currentUser: currentUser,
                      targetUser: targetUser,
                    ),
                    icon: Icon(friendButtonIcon, size: 17, color: friendButtonColor),
                    label: Text(
                      friendButtonText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: friendButtonColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: friendButtonColor.withValues(alpha: 0.6), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 3: Theo dõi (Follow / Following)
                InkWell(
                  onTap: () {
                    context.read<FriendshipCubit>().toggleFollow(
                          currentUserId: currentUser.uid,
                          targetUserId: targetUser.uid,
                        );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? AppTheme.accentColor(context).withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFollowing
                            ? AppTheme.accentColor(context)
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFollowing ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 18,
                          color: isFollowing ? AppTheme.accentColor(context) : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFollowing ? AppTheme.accentColor(context) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDigitalCard(BuildContext context, UserEntity user) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF0C4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context)
                ? Colors.black54
                : const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo/phenikaa_logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.university_name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SINH VIÊN',
                  style: TextStyle(color: Color(0xFFFFB088), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.accentColor(context),
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MSSV: ${user.studentId.isNotEmpty ? user.studentId : '23010390'} • K${user.cohort != 0 ? user.cohort : 17}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                    Text(
                      'Khoa: ${user.faculty.isNotEmpty ? user.faculty : 'Công nghệ thông tin'}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💬 "${user.bio}"',
                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, UserEntity user) {
    return BlocBuilder<FriendshipCubit, FriendshipState>(
      builder: (context, fState) {
        final rel = fState.relationship;
        final friendsCount = rel.friendsCount > 0 ? rel.friendsCount : user.friendsCount;
        final followersCount = rel.followersCount;
        final followingCount = rel.followingCount;

        return Row(
          children: [
            Expanded(
              child: _buildSingleMetric(
                context,
                title: 'Bài viết',
                value: '${user.postsCount}',
                icon: Icons.article_rounded,
                color: AppTheme.primaryColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSingleMetric(
                context,
                title: 'Bạn bè',
                value: '$friendsCount',
                icon: Icons.people_rounded,
                color: AppTheme.mintColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSingleMetric(
                context,
                title: 'Follower',
                value: '$followersCount',
                icon: Icons.groups_rounded,
                color: AppTheme.accentColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSingleMetric(
                context,
                title: 'Following',
                value: '$followingCount',
                icon: Icons.person_pin_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleMetric(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(BuildContext context, UserEntity user, String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.postsCollection)
          .where('authorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 54, color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.no_posts_empty,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          );
        }

        final posts = docs.map((doc) => PostModel.fromFirestore(doc)).toList();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final isOwner = currentUid.isNotEmpty && (post.authorId == currentUid || user.uid == currentUid);
            return PostCard(
              post: post,
              currentUserId: currentUid,
              onLikePressed: () {
                context.read<FeedCubit>().toggleLike(post, currentUid);
              },
              onCommentPressed: () {
                PostCommentsBottomSheet.show(
                  context,
                  post: post,
                  currentUserId: currentUid,
                  currentUserName: user.displayName,
                  currentUserAvatar: user.avatarUrl,
                  currentUserStudentId: user.studentId,
                  currentUserFaculty: user.faculty,
                );
              },
              onEditPressed: isOwner
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
              onDeletePressed: isOwner
                  ? () async {
                      try {
                        await context.read<FeedCubit>().deletePost(post.postId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.delete_post_success),
                              backgroundColor: AppTheme.primaryColor(context),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi khi xóa bài: $e'),
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
        );
      },
    );
  }

  Widget _buildFriendsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<FriendshipCubit, FriendshipState>(
      builder: (context, fState) {
        final friends = fState.friendsList;

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 54, color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Chưa có bạn bè nào',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final friend = friends[index];
            final fId = friend['userId'] as String? ?? '';
            final fName = friend['displayName'] as String? ?? 'Sinh viên Phenikaa';
            final fAvatar = friend['avatarUrl'] as String? ?? '';
            final fFaculty = friend['faculty'] as String? ?? '';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor(context),
                  backgroundImage: fAvatar.isNotEmpty ? NetworkImage(fAvatar) : null,
                  child: fAvatar.isEmpty
                      ? Text(
                          fName.isNotEmpty ? fName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(fName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  fFaculty.isNotEmpty ? fFaculty : 'Đại học Phenikaa',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        userId: fId,
                        userName: fName,
                        faculty: fFaculty,
                        avatarUrl: fAvatar,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsTab(BuildContext context, UserEntity user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.studyDocumentsCollection)
          .where('authorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 54, color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.no_docs_found,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          );
        }

        final documents = docs.map((doc) => DocumentModel.fromFirestore(doc)).toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final document = documents[index];
            return DocumentCard(
              document: document,
              onDownload: () {
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.downloading} ${document.title}')),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin học tập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildInfoTile(Icons.badge_outlined, 'Mã số sinh viên', user.studentId.isNotEmpty ? user.studentId : '23010390'),
              _buildInfoTile(Icons.school_outlined, 'Khoa / Viện', user.faculty.isNotEmpty ? user.faculty : 'Khoa Công nghệ thông tin'),
              _buildInfoTile(Icons.book_outlined, 'Chuyên ngành', user.major.isNotEmpty ? user.major : 'Kỹ thuật phần mềm'),
              _buildInfoTile(Icons.calendar_today_outlined, 'Khóa đào tạo', 'K${user.cohort != 0 ? user.cohort : 17} (2023 - 2027)'),
              _buildInfoTile(Icons.email_outlined, 'Email liên hệ', user.email),
              if (user.currentSubjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text('Môn học đang theo học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.currentSubjects.map((sub) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.blueContainer(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
