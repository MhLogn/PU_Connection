import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/datasources/phenikaa_student_directory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../cubit/chat_cubit.dart';
import '../pages/chat_detail_page.dart';

class GroupMember {
  final String id;
  final String name;
  final String studentId;
  final String faculty;
  final String major;
  final int cohort;
  final String email;
  final String avatarUrl;
  final bool isAdmin;
  final bool isMe;

  const GroupMember({
    required this.id,
    required this.name,
    this.studentId = '',
    this.faculty = '',
    this.major = '',
    this.cohort = 17,
    this.email = '',
    this.avatarUrl = '',
    this.isAdmin = false,
    this.isMe = false,
  });
}

class GroupInfoBottomSheet extends StatefulWidget {
  final String? conversationId;
  final ConversationEntity? conversation;
  final String fallbackGroupName;
  final List<String> fallbackParticipantIds;

  const GroupInfoBottomSheet({
    super.key,
    this.conversation,
    this.conversationId,
    this.fallbackGroupName = '',
    this.fallbackParticipantIds = const [],
  });

  String get effectiveConversationId =>
      (conversationId != null && conversationId!.isNotEmpty)
          ? conversationId!
          : (conversation?.id ?? '');

  @override
  State<GroupInfoBottomSheet> createState() => _GroupInfoBottomSheetState();
}

class _GroupInfoBottomSheetState extends State<GroupInfoBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GroupMember> _memberCache = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<GroupMember> _resolveMemberDetails({
    required String memberId,
    required String fallbackName,
    required String fallbackFaculty,
    required String fallbackAvatar,
    required String adminId,
    required String currentUserId,
  }) async {
    if (_memberCache.containsKey(memberId)) {
      return _memberCache[memberId]!;
    }

    String name = fallbackName;
    String studentId = '';
    String faculty = fallbackFaculty;
    String major = '';
    int cohort = 17;
    String email = '';
    String avatarUrl = fallbackAvatar;

    // 1. Check users collection in Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .doc(memberId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        name = data['displayName'] as String? ?? data['fullName'] as String? ?? name;
        studentId = data['studentId'] as String? ?? data['username'] as String? ?? studentId;
        faculty = data['faculty'] as String? ?? faculty;
        major = data['major'] as String? ?? major;
        cohort = (data['cohort'] is num) ? (data['cohort'] as num).toInt() : cohort;
        email = data['email'] as String? ?? email;
        avatarUrl = data['avatarUrl'] as String? ?? avatarUrl;
      }
    } catch (_) {}

    // 2. Check phenikaa_students collection
    if (studentId.isEmpty || faculty.isEmpty) {
      try {
        final sDoc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.phenikaaStudentsCollection)
            .doc(memberId)
            .get();
        if (sDoc.exists && sDoc.data() != null) {
          final data = sDoc.data()!;
          name = data['fullName'] as String? ?? data['name'] as String? ?? name;
          studentId = data['studentId'] as String? ?? studentId;
          faculty = data['faculty'] as String? ?? faculty;
          major = data['major'] as String? ?? major;
          cohort = (data['cohort'] is num) ? (data['cohort'] as num).toInt() : cohort;
          email = data['email'] as String? ?? email;
        }
      } catch (_) {}
    }

    // 3. Fallback to PhenikaaStudentDirectory
    final match = PhenikaaStudentDirectory.defaultStudents.where(
      (s) =>
          s.studentId == memberId ||
          (studentId.isNotEmpty && s.studentId == studentId) ||
          (name.isNotEmpty && s.fullName.toLowerCase() == name.toLowerCase()),
    );
    if (match.isNotEmpty) {
      final s = match.first;
      if (name.isEmpty || name == 'Sinh viên Phenikaa') name = s.fullName;
      if (studentId.isEmpty) studentId = s.studentId;
      if (faculty.isEmpty) faculty = s.faculty;
      if (major.isEmpty) major = s.major;
      cohort = s.cohort;
      if (email.isEmpty) email = s.email;
    }

    if (email.isEmpty && studentId.isNotEmpty) {
      email = '$studentId@st.phenikaa-uni.edu.vn';
    }

    final resolved = GroupMember(
      id: memberId,
      name: name.isNotEmpty ? name : 'Sinh viên Phenikaa',
      studentId: studentId,
      faculty: faculty.isNotEmpty ? faculty : 'Phenikaa University',
      major: major.isNotEmpty ? major : 'Sinh viên chính quy',
      cohort: cohort,
      email: email,
      avatarUrl: avatarUrl,
      isAdmin: adminId.isNotEmpty && adminId == memberId,
      isMe: currentUserId.isNotEmpty && currentUserId == memberId,
    );

    _memberCache[memberId] = resolved;
    return resolved;
  }

  void _showMemberDetail(BuildContext context, GroupMember member) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    final initials = member.name.isNotEmpty
        ? member.name.trim().split(' ').last[0].toUpperCase()
        : 'P';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (detailCtx) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(detailCtx).padding.bottom),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_rounded, size: 16, color: AppTheme.primaryColor(context)),
                      const SizedBox(width: 6),
                      Text(
                        'THẺ THÀNH VIÊN NHÓM',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(detailCtx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.blueContainer(context),
                    backgroundImage: member.avatarUrl.isNotEmpty
                        ? NetworkImage(member.avatarUrl)
                        : null,
                    child: member.avatarUrl.isEmpty
                        ? Text(
                            initials,
                            style: TextStyle(
                              color: AppTheme.primaryColor(context),
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified_rounded,
                    color: AppTheme.primaryColor(context),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor(context).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 13, color: AppTheme.accentColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Trưởng nhóm',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (member.isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Bạn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'MSSV',
                    value: member.studentId.isNotEmpty ? member.studentId : 'Chưa cập nhật',
                    canCopy: member.studentId.isNotEmpty,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.account_balance_rounded,
                    label: 'Khoa',
                    value: member.faculty,
                  ),
                  if (member.major.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      icon: Icons.school_outlined,
                      label: 'Ngành học',
                      value: member.major,
                    ),
                  ],
                  const Divider(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Khóa sinh viên',
                    value: 'Khóa K${member.cohort}',
                  ),
                  if (member.email.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email sinh viên',
                      value: member.email,
                      canCopy: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!member.isMe) ...[
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(detailCtx);
                    final authState = context.read<AuthCubit>().state;
                    if (authState is! Authenticated) return;
                    final currentUid = authState.user.uid;
                    final currentName = authState.user.displayName.isNotEmpty
                        ? authState.user.displayName
                        : 'Sinh viên Phenikaa';
                    final currentAvatar = authState.user.avatarUrl;
                    final currentFac = authState.user.faculty;

                    try {
                      final convId = await context.read<ChatCubit>().startDirectChat(
                            currentUserId: currentUid,
                            currentUserName: currentName,
                            currentUserAvatar: currentAvatar,
                            currentUserFaculty: currentFac,
                            otherUserId: member.id,
                            otherUserName: member.name,
                            otherUserAvatar: member.avatarUrl,
                            otherUserFaculty: member.faculty,
                          );

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(
                              conversationId: convId,
                              otherUserId: member.id,
                              otherUserName: member.name,
                              otherUserAvatar: member.avatarUrl,
                              otherUserFaculty: member.faculty,
                              participantIds: [currentUid, member.id]..sort(),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Không thể mở tin nhắn 1-1: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('Nhắn tin riêng với ${member.name.split(' ').last}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(detailCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userId: member.id,
                          userName: member.name,
                          studentId: member.studentId,
                          faculty: member.faculty,
                          avatarUrl: member.avatarUrl,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('Xem hồ sơ cá nhân đầy đủ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor(context),
                    side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(detailCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userId: member.id,
                          userName: member.name,
                          studentId: member.studentId,
                          faculty: member.faculty,
                          avatarUrl: member.avatarUrl,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_circle_outlined, size: 18),
                  label: const Text('Xem trang cá nhân của tôi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor(context),
                    side: BorderSide(color: AppTheme.primaryColor(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.primaryColor(context)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (canCopy) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép $value'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Icon(
              Icons.copy_rounded,
              size: 15,
              color: AppTheme.primaryColor(context),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmLeaveGroup(BuildContext context, String groupName) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final currentUserId = authState.user.uid;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rời khỏi nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn rời nhóm "$groupName" không? Bạn sẽ không nhận được tin nhắn từ nhóm này nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && context.mounted) {
      final chatCubit = context.read<ChatCubit>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      try {
        await chatCubit.leaveGroup(
          conversationId: widget.effectiveConversationId,
          userId: currentUserId,
        );
        nav.pop(); // Close bottom sheet
        nav.pop(); // Pop chat detail page
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Đã rời khỏi nhóm "$groupName"')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lỗi khi rời nhóm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final convId = widget.effectiveConversationId;

    return StreamBuilder<DocumentSnapshot>(
      stream: convId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection(FirebaseConstants.chatsCollection)
              .doc(convId)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        ConversationEntity conv;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          conv = ConversationModel.fromFirestore(snapshot.data!);
        } else if (widget.conversation != null) {
          conv = widget.conversation!;
        } else {
          conv = ConversationEntity(
            id: convId.isNotEmpty ? convId : 'group_chat',
            isGroup: true,
            groupName: widget.fallbackGroupName.isNotEmpty ? widget.fallbackGroupName : 'Nhóm trò chuyện',
            participantIds: widget.fallbackParticipantIds,
            participantNames: const {},
          );
        }

        final groupName = conv.groupName.isNotEmpty
            ? conv.groupName
            : (widget.fallbackGroupName.isNotEmpty ? widget.fallbackGroupName : 'Nhóm trò chuyện');

        final groupInitial = groupName.isNotEmpty
            ? groupName.trim()[0].toUpperCase()
            : 'N';

        final memberIds = conv.participantIds.isNotEmpty
            ? conv.participantIds
            : widget.fallbackParticipantIds;

        final adminId = conv.adminId;

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.groups_rounded,
                            color: AppTheme.primaryColor(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Thông tin nhóm',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.primaryColor(context),
                  child: Text(
                    groupInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  groupName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${memberIds.length} thành viên tham gia',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm thành viên trong nhóm...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 17),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách thành viên (${memberIds.length})',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                    Text(
                      'Nhấn để xem chi tiết',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: memberIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final mId = memberIds[index];
                    final fallbackName = conv.participantNames[mId] ?? 'Sinh viên Phenikaa';
                    final fallbackFaculty = conv.participantFaculties[mId] ?? '';
                    final fallbackAvatar = conv.participantAvatars[mId] ?? '';

                    return FutureBuilder<GroupMember>(
                      future: _resolveMemberDetails(
                        memberId: mId,
                        fallbackName: fallbackName,
                        fallbackFaculty: fallbackFaculty,
                        fallbackAvatar: fallbackAvatar,
                        adminId: adminId,
                        currentUserId: currentUserId,
                      ),
                      builder: (context, memberSnap) {
                        final member = memberSnap.data ??
                            GroupMember(
                              id: mId,
                              name: fallbackName,
                              faculty: fallbackFaculty,
                              isAdmin: adminId.isNotEmpty && adminId == mId,
                              isMe: currentUserId.isNotEmpty && currentUserId == mId,
                            );

                        if (_searchQuery.isNotEmpty) {
                          final matchName = member.name.toLowerCase().contains(_searchQuery);
                          final matchId = member.studentId.toLowerCase().contains(_searchQuery);
                          final matchFac = member.faculty.toLowerCase().contains(_searchQuery);
                          if (!matchName && !matchId && !matchFac) {
                            return const SizedBox.shrink();
                          }
                        }

                        final initials = member.name.isNotEmpty
                            ? member.name.trim().split(' ').last[0].toUpperCase()
                            : 'P';

                        return Container(
                          decoration: BoxDecoration(
                            color: member.isMe
                                ? AppTheme.primaryColor(context).withValues(alpha: 0.05)
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: member.isMe
                                  ? AppTheme.primaryColor(context).withValues(alpha: 0.3)
                                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _showMemberDetail(context, member),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: member.isAdmin
                                              ? AppTheme.accentColor(context).withValues(alpha: 0.2)
                                              : AppTheme.blueContainer(context),
                                          backgroundImage: member.avatarUrl.isNotEmpty
                                              ? NetworkImage(member.avatarUrl)
                                              : null,
                                          child: member.avatarUrl.isEmpty
                                              ? Text(
                                                  initials,
                                                  style: TextStyle(
                                                    color: member.isAdmin
                                                        ? AppTheme.accentColor(context)
                                                        : AppTheme.primaryColor(context),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: colorScheme.surface, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  member.isMe ? '${member.name} (Bạn)' : member.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (member.isAdmin) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accentColor(context)
                                                        .withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Trưởng nhóm',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.accentColor(context),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            member.studentId.isNotEmpty
                                                ? 'MSSV: ${member.studentId} • ${member.faculty}'
                                                : (member.faculty.isNotEmpty
                                                    ? member.faculty
                                                    : 'Sinh viên Phenikaa'),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLeaveGroup(context, groupName),
                    icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 18),
                    label: const Text(
                      'Rời khỏi nhóm trò chuyện',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
