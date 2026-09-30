import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/group_info_bottom_sheet.dart';

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final bool isGroup;
  final String groupName;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserFaculty;
  final List<String> participantIds;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    this.isGroup = false,
    this.groupName = '',
    this.otherUserId = '',
    this.otherUserName = '',
    this.otherUserAvatar = '',
    this.otherUserFaculty = '',
    required this.participantIds,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    context.read<ChatCubit>().openConversation(
      widget.conversationId,
      currentUserId,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  void _showImagePickerOptions() {
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
              ListTile(
                leading: Icon(
                  Icons.photo_camera_rounded,
                  color: AppTheme.primaryColor(context),
                ),
                title: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.accentColor(context),
                ),
                title: const Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _openHeaderTarget() {
    if (widget.isGroup) {
      final conversations = context.read<ChatCubit>().state.conversations;
      final currentConv = conversations.firstWhere(
        (c) => c.id == widget.conversationId,
        orElse: () => ConversationEntity(
          id: widget.conversationId,
          isGroup: true,
          groupName: widget.groupName,
          participantIds: widget.participantIds,
          participantNames: const {},
        ),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GroupInfoBottomSheet(conversation: currentConv),
      );
    } else {
      if (widget.otherUserId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              userId: widget.otherUserId,
              userName: widget.otherUserName,
              faculty: widget.otherUserFaculty,
              avatarUrl: widget.otherUserAvatar,
            ),
          ),
        );
      }
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.uid;
    final currentUserName = authState.user.displayName.isNotEmpty
        ? authState.user.displayName
        : 'Sinh viên Phenikaa';
    final currentUserAvatar = authState.user.avatarUrl;

    final imageToSend = _selectedImage;
    _textController.clear();
    setState(() {
      _selectedImage = null;
    });

    context.read<ChatCubit>().sendMessage(
      conversationId: widget.conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: text,
      imageFile: imageToSend,
      participantIds: widget.participantIds,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';

    final displayName = widget.isGroup
        ? (widget.groupName.isNotEmpty ? widget.groupName : 'Nhóm trò chuyện')
        : widget.otherUserName;

    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').last[0].toUpperCase()
        : (widget.isGroup ? 'N' : 'P');

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openHeaderTarget,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: widget.isGroup
                          ? AppTheme.primaryColor(context)
                          : AppTheme.blueContainer(context),
                      child: widget.isGroup
                          ? const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              initials,
                              style: TextStyle(
                                color: AppTheme.primaryColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                    if (!widget.isGroup)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.isGroup
                            ? '${widget.participantIds.length} thành viên • Nhấn để xem'
                            : (widget.otherUserFaculty.isNotEmpty
                                  ? '${widget.otherUserFaculty} • Nhấn để xem hồ sơ'
                                  : 'Sinh viên Phenikaa'),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isGroup
                  ? Icons.info_outline_rounded
                  : Icons.account_circle_outlined,
              color: AppTheme.primaryColor(context),
            ),
            tooltip: widget.isGroup ? 'Thông tin nhóm' : 'Trang cá nhân',
            onPressed: _openHeaderTarget,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                _scrollToBottom();
              },
              builder: (context, state) {
                final messages = state.currentMessages;

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isGroup
                                ? Icons.forum_rounded
                                : Icons.waving_hand_rounded,
                            size: 48,
                            color: AppTheme.accentColor(context),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.isGroup
                                ? 'Chào mừng bạn đến với nhóm!'
                                : 'Gửi lời chào tới $displayName!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isGroup
                                ? 'Cùng thảo luận bài giảng, chia sẻ tài liệu và kết nối nhóm học tập nhé.'
                                : 'Bắt đầu chia sẻ tài liệu học tập, trao đổi bài tập hoặc kết nối bạn bè ngay hôm nay.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageRow(
                      context,
                      message,
                      isMe,
                      isDark,
                      colorScheme,
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedImage != null) _buildSelectedImagePreview(colorScheme),
          _buildInputBar(context, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hình ảnh đã sẵn sàng để gửi',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context,
    MessageEntity message,
    bool isMe,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    if (widget.isGroup && !isMe) {
      final senderInitials = message.senderName.isNotEmpty
          ? message.senderName.trim().split(' ').last[0].toUpperCase()
          : 'P';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.blueContainer(context),
            child: Text(
              senderInitials,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                ),
                _buildMessageBubble(
                  context,
                  message,
                  isMe,
                  isDark,
                  colorScheme,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildMessageBubble(context, message, isMe, isDark, colorScheme),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageEntity message,
    bool isMe,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.oceanGradient : null,
          color: isMe
              ? null
              : (isDark
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      )
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _viewFullImage(message.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 180,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              if (message.content.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final chatState = context.watch<ChatCubit>().state;
    final isSending = chatState.isSending;

    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              color: AppTheme.primaryColor(context),
              size: 24,
            ),
            tooltip: 'Gửi hình ảnh',
            onPressed: isSending ? null : _showImagePickerOptions,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: widget.isGroup
                      ? 'Nhập tin nhắn vào nhóm...'
                      : 'Nhập tin nhắn cho ${widget.otherUserName}...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor(context),
                    const Color(0xFFFF9E45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor(context).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
