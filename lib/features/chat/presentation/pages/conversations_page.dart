import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/conversation_entity.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/create_group_bottom_sheet.dart';
import '../widgets/new_chat_bottom_sheet.dart';
import 'chat_detail_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ChatCubit>().initConversations(authState.user.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChatActionSheet() {
    final colorScheme = Theme.of(context).colorScheme;

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
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Bắt đầu trò chuyện',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(
                      context,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
                title: const Text(
                  'Nhắn tin trực tiếp (1-1)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tìm kiếm và nhắn tin cho bạn bè, sinh viên Phenikaa',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDirectChatModal();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor(
                      context,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: AppTheme.accentColor(context),
                  ),
                ),
                title: const Text(
                  'Tạo nhóm trò chuyện',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tạo nhóm học tập, đồ án hoặc sinh hoạt CLB',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateGroupModal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirectChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NewChatBottomSheet(),
    );
  }

  void _openCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateGroupBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppTheme.isDark(context) ? Colors.white : AppTheme.deepBlue,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Nhắn tin mới',
            onPressed: _openChatActionSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatActionSheet,
        backgroundColor: AppTheme.accentColor(context),
        foregroundColor: Colors.white,
        tooltip: 'Soạn tin nhắn mới',
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add_comment_rounded, size: 22),
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final conversations = state.conversations.where((conv) {
            if (_searchQuery.isEmpty) return true;
            final displayName = conv
                .getDisplayName(currentUserId)
                .toLowerCase();
            final lastMsg = conv.lastMessage.toLowerCase();
            return displayName.contains(_searchQuery) ||
                lastMsg.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppTheme.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.02,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm cuộc trò chuyện, nhóm...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildConversationList(
                  context,
                  state,
                  conversations,
                  currentUserId,
                  localeCode,
                  colorScheme,
                  isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    ChatState state,
    List<ConversationEntity> conversations,
    String currentUserId,
    String localeCode,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (state.status == ChatStatus.loading && state.conversations.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor(context)),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 46,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy cuộc trò chuyện nào'
                    : 'Chưa có cuộc trò chuyện nào',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Thử tìm kiếm với tên hoặc từ khóa khác'
                    : 'Hãy kết nối, trò chuyện với bạn bè hoặc tạo nhóm học tập ngay hôm nay!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openChatActionSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Bắt đầu trò chuyện'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final isGroup = conv.isGroup;
        final displayName = conv.getDisplayName(currentUserId);
        final otherId = conv.getOtherParticipantId(currentUserId);
        final otherName = conv.getOtherParticipantName(currentUserId);
        final otherFaculty = conv.getOtherParticipantFaculty(currentUserId);
        final otherAvatar = conv.getOtherParticipantAvatar(currentUserId);
        final unreadCount = conv.getUnreadCount(currentUserId);
        final hasUnread = unreadCount > 0;
        final timeStr = conv.lastMessageAt != null
            ? timeago.format(conv.lastMessageAt!, locale: localeCode)
            : '';

        final initials = displayName.isNotEmpty
            ? (isGroup
                  ? displayName.trim()[0].toUpperCase()
                  : displayName.trim().split(' ').last[0].toUpperCase())
            : (isGroup ? 'N' : 'P');

        final isMeLastSender = conv.lastMessageSenderId == currentUserId;
        String displayLastMessage;
        if (conv.lastMessage.isEmpty) {
          displayLastMessage = 'Chưa có tin nhắn';
        } else if (isMeLastSender) {
          displayLastMessage = 'Bạn: ${conv.lastMessage}';
        } else if (isGroup) {
          final senderName = conv.participantNames[conv.lastMessageSenderId];
          final shortSenderName = senderName != null && senderName.isNotEmpty
              ? senderName.split(' ').last
              : '';
          displayLastMessage = shortSenderName.isNotEmpty
              ? '$shortSenderName: ${conv.lastMessage}'
              : conv.lastMessage;
        } else {
          displayLastMessage = conv.lastMessage;
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.accentColor(context).withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : AppTheme.borderLight),
              width: hasUnread ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(
                      conversationId: conv.id,
                      isGroup: isGroup,
                      groupName: isGroup ? conv.groupName : '',
                      otherUserId: isGroup ? '' : otherId,
                      otherUserName: isGroup ? conv.groupName : otherName,
                      otherUserAvatar: isGroup ? conv.groupAvatar : otherAvatar,
                      otherUserFaculty: isGroup ? '' : otherFaculty,
                      participantIds: conv.participantIds,
                    ),
                  ),
                );
              },
              onLongPress: () {
                _showConversationActions(context, conv, currentUserId);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isGroup
                              ? AppTheme.primaryColor(context)
                              : AppTheme.blueContainer(context),
                          child: isGroup
                              ? const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : Text(
                                  initials,
                                  style: TextStyle(
                                    color: AppTheme.primaryColor(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        if (!isGroup && otherId.isNotEmpty)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection(FirebaseConstants.usersCollection)
                                .doc(otherId)
                                .snapshots(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData || !userSnap.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              final data =
                                  userSnap.data!.data()
                                      as Map<String, dynamic>?;
                              final rawOnline =
                                  data?['isOnline'] as bool? ?? false;
                              final lastActiveTs =
                                  data?['lastActive'] as Timestamp?;
                              final lastActive = lastActiveTs?.toDate();
                              final isOnline = rawOnline &&
                                  lastActive != null &&
                                  DateTime.now()
                                          .difference(lastActive)
                                          .inMinutes <=
                                      5;
                              if (!isOnline) return const SizedBox.shrink();
                              return Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasUnread
                                      ? AppTheme.accentColor(context)
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isGroup) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor(
                                      context,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group_rounded,
                                        size: 11,
                                        color: AppTheme.accentColor(context),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${conv.participantIds.length} TV',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.accentColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (otherFaculty.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(
                                      context,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    otherFaculty,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  displayLastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: hasUnread
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                  ),
                                ),
                              ),
                              if (hasUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConversationActions(
    BuildContext context,
    ConversationEntity conv,
    String currentUserId,
  ) {
    final displayName = conv.getDisplayName(currentUserId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Xóa đoạn chat',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Ẩn lịch sử cuộc trò chuyện này khỏi danh sách',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Xóa đoạn chat?'),
                      content: Text(
                        'Bạn có chắc chắn muốn xóa đoạn chat với "$displayName"? Lịch sử trò chuyện sẽ được ẩn khỏi danh sách của bạn.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context
                                .read<ChatCubit>()
                                .deleteConversationForUser(
                                  conversationId: conv.id,
                                  userId: currentUserId,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa đoạn chat thành công.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
