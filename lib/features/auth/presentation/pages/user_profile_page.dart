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
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/widgets/post_comments_bottom_sheet.dart';
import '../../../documents/data/models/document_model.dart';
import '../../../documents/presentation/widgets/document_card.dart';

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
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnectionStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUid = authState.user.uid;
    if (currentUid.isEmpty || widget.userId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUid)
          .collection(FirebaseConstants.friendsSubcollection)
          .doc(widget.userId)
          .get();

      if (mounted) {
        setState(() {
          _isConnected = doc.exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleConnection() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUid = authState.user.uid;
    final targetUid = widget.userId;
    if (currentUid == targetUid || targetUid.isEmpty) return;

    final willConnect = !_isConnected;
    setState(() => _isConnected = willConnect);

    try {
      final myFriendsRef = FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUid)
          .collection(FirebaseConstants.friendsSubcollection)
          .doc(targetUid);

      final targetFollowersRef = FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .doc(targetUid)
          .collection(FirebaseConstants.followersSubcollection)
          .doc(currentUid);

      if (willConnect) {
        await myFriendsRef.set({
          'userId': targetUid,
          'connectedAt': FieldValue.serverTimestamp(),
        });
        await targetFollowersRef.set({
          'userId': currentUid,
          'connectedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã kết nối với ${widget.userName}!'),
              backgroundColor: AppTheme.primaryColor(context),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await myFriendsRef.delete();
        await targetFollowersRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã hủy kết nối với ${widget.userName}.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final currentUid = authState is Authenticated ? authState.user.uid : '';
    final isSelf = currentUid.isNotEmpty && currentUid == widget.userId;

    return StreamBuilder<DocumentSnapshot>(
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
          // Fallback matching directory
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
              if (!isSelf)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Chia sẻ hồ sơ',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép liên kết hồ sơ của ${user.displayName}!')),
                    );
                  },
                ),
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

                      // Action buttons: Nhắn tin & Kết nối
                      if (!isSelf) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: _startChat,
                                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                                label: const Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor(context),
                                  foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: _toggleConnection,
                                icon: Icon(
                                  _isConnected ? Icons.check_circle_rounded : Icons.person_add_rounded,
                                  size: 18,
                                  color: _isConnected ? AppTheme.mintColor(context) : AppTheme.accentColor(context),
                                ),
                                label: Text(
                                  _isConnected ? 'Đã kết nối' : 'Kết nối',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isConnected ? AppTheme.mintColor(context) : AppTheme.accentColor(context),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _isConnected
                                        ? AppTheme.mintColor(context).withValues(alpha: 0.5)
                                        : AppTheme.accentColor(context).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Metric counts
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
                _buildDocumentsTab(context, user),
                _buildAboutTab(context, user),
              ],
            ),
          ),
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
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
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
    return Row(
      children: [
        Expanded(
          child: _buildSingleMetric(
            context,
            title: 'Khóa học',
            value: 'K${user.cohort != 0 ? user.cohort : 17}',
            icon: Icons.school_rounded,
            color: AppTheme.primaryColor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleMetric(
            context,
            title: 'Trạng thái',
            value: 'Chính quy',
            icon: Icons.verified_user_rounded,
            color: AppTheme.mintColor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleMetric(
            context,
            title: 'Độ tin cậy',
            value: '100%',
            icon: Icons.thumb_up_alt_rounded,
            color: AppTheme.accentColor(context),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withValues(alpha: 0.55)),
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
                  'Sinh viên này chưa đăng bài viết nào',
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
                  'Chưa có tài liệu đóng góp nào',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đang tải: ${document.title}')),
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
