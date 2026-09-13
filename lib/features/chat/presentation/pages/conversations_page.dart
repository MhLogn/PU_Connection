import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/conversation_entity.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
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

  void _openNewChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NewChatBottomSheet(),
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
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Nhắn tin mới',
            onPressed: _openNewChatModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChatModal,
        backgroundColor: AppTheme.accentColor(context),
        foregroundColor: Colors.white,
        tooltip: 'Soạn tin nhắn mới',
        child: const Icon(Icons.add_comment_rounded, size: 24),
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final conversations = state.conversations.where((conv) {
            if (_searchQuery.isEmpty) return true;
            final otherName = conv.getOtherParticipantName(currentUserId).toLowerCase();
            final lastMsg = conv.lastMessage.toLowerCase();
            return otherName.contains(_searchQuery) || lastMsg.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                      hintText: 'Tìm kiếm cuộc trò chuyện, bạn bè...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Thử tìm kiếm với tên hoặc từ khóa khác'
                    : 'Hãy kết nối và trò chuyện với bạn bè, sinh viên cùng khoa!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openNewChatModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Bắt đầu trò chuyện'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        final otherId = conv.getOtherParticipantId(currentUserId);
        final otherName = conv.getOtherParticipantName(currentUserId);
        final otherFaculty = conv.getOtherParticipantFaculty(currentUserId);
        final otherAvatar = conv.getOtherParticipantAvatar(currentUserId);
        final unreadCount = conv.getUnreadCount(currentUserId);
        final hasUnread = unreadCount > 0;
        final timeStr = conv.lastMessageAt != null
            ? timeago.format(conv.lastMessageAt!, locale: localeCode)
            : '';

        final initials = otherName.isNotEmpty
            ? otherName.trim().split(' ').last[0].toUpperCase()
            : 'P';

        final isMeLastSender = conv.lastMessageSenderId == currentUserId;
        final displayLastMessage = conv.lastMessage.isNotEmpty
            ? (isMeLastSender ? 'Bạn: ${conv.lastMessage}' : conv.lastMessage)
            : 'Chưa có tin nhắn';

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.accentColor(context).withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: hasUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(
                      conversationId: conv.id,
                      otherUserId: otherId,
                      otherUserName: otherName,
                      otherUserAvatar: otherAvatar,
                      otherUserFaculty: otherFaculty,
                      participantIds: conv.participantIds,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.blueContainer(context),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: AppTheme.primaryColor(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  otherName,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
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
                                      : colorScheme.onSurface.withValues(alpha: 0.45),
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (otherFaculty.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
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
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                    color: hasUnread
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              if (hasUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
}
