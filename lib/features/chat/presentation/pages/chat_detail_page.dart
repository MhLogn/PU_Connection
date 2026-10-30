import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/conversation_entity.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_message_bubble.dart';
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
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;
  Timer? _typingTimer;
  bool _isTyping = false;

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
    _typingTimer?.cancel();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ChatCubit>().setTypingStatus(
        conversationId: widget.conversationId,
        userId: authState.user.uid,
        isTyping: false,
      );
    }
    context.read<ChatCubit>().closeCurrentConversation(widget.conversationId);
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


  void _openHeaderTarget() {
    if (widget.isGroup) {
      final conversations = context.read<ChatCubit>().state.conversations;
      final matchingConvs = conversations.where(
        (c) => c.id == widget.conversationId,
      );
      final currentConv = matchingConvs.isNotEmpty
          ? matchingConvs.first
          : ConversationEntity(
              id: widget.conversationId,
              isGroup: true,
              groupName: widget.groupName,
              participantIds: widget.participantIds,
              participantNames: const {},
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

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'pptx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final sizeInBytes = await file.length();
        String sizeFormatted = '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
        if (sizeInBytes > 1024 * 1024) {
          sizeFormatted =
              '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        setState(() {
          _selectedFile = file;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = sizeFormatted;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chọn tệp: $e')));
      }
    }
  }

  void _onTypingChanged(String val) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final currentUserId = authState.user.uid;

    if (val.trim().isNotEmpty) {
      if (!_isTyping) {
        _isTyping = true;
        context.read<ChatCubit>().setTypingStatus(
          conversationId: widget.conversationId,
          userId: currentUserId,
          isTyping: true,
        );
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 2500), () {
        _isTyping = false;
        context.read<ChatCubit>().setTypingStatus(
          conversationId: widget.conversationId,
          userId: currentUserId,
          isTyping: false,
        );
      });
    } else {
      if (_isTyping) {
        _isTyping = false;
        _typingTimer?.cancel();
        context.read<ChatCubit>().setTypingStatus(
          conversationId: widget.conversationId,
          userId: currentUserId,
          isTyping: false,
        );
      }
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null && _selectedFile == null) return;

    // Tiền kiểm tra từ ngữ không phù hợp (Bad Words Filter) trước khi gửi tin nhắn
    if (text.isNotEmpty && sl.isRegistered<BadWordsFilterService>()) {
      final checkResult = sl<BadWordsFilterService>().check(
        text,
        actionLabel: 'gửi tin nhắn',
      );
      if (!checkResult.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkResult.suggestionMessage ??
                  'Tin nhắn chứa từ ngữ không phù hợp với chuẩn mực văn hóa Phenikaa.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.uid;
    final currentUserName = authState.user.displayName.isNotEmpty
        ? authState.user.displayName
        : 'Sinh viên Phenikaa';
    final currentUserAvatar = authState.user.avatarUrl;

    final imageToSend = _selectedImage;
    final fileToSend = _selectedFile;
    final fileNameToSend = _selectedFileName;
    final fileSizeToSend = _selectedFileSize;

    _textController.clear();
    _onTypingChanged('');

    setState(() {
      _selectedImage = null;
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });

    context.read<ChatCubit>().sendMessage(
      conversationId: widget.conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: text,
      imageFile: imageToSend,
      docFile: fileToSend,
      fileName: fileNameToSend,
      fileSize: fileSizeToSend,
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
                    if (!widget.isGroup && widget.otherUserId.isNotEmpty)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(FirebaseConstants.usersCollection)
                            .doc(widget.otherUserId)
                            .snapshots(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists) {
                            return const SizedBox.shrink();
                          }
                          final data =
                              userSnap.data!.data() as Map<String, dynamic>?;
                          final rawOnline = data?['isOnline'] as bool? ?? false;
                          final lastActiveTs =
                              data?['lastActive'] as Timestamp?;
                          final lastActive = lastActiveTs?.toDate();
                          final isOnline = rawOnline &&
                              lastActive != null &&
                              DateTime.now().difference(lastActive).inMinutes <=
                                  5;
                          if (!isOnline) return const SizedBox.shrink();
                          return Positioned(
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
                          );
                        },
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
                      if (widget.isGroup)
                        Text(
                          '${widget.participantIds.length} thành viên • Nhấn để xem',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        StreamBuilder<DocumentSnapshot>(
                          stream: widget.otherUserId.isNotEmpty
                              ? FirebaseFirestore.instance
                                    .collection(
                                      FirebaseConstants.usersCollection,
                                    )
                                    .doc(widget.otherUserId)
                                    .snapshots()
                              : null,
                          builder: (context, userSnap) {
                            final data =
                                userSnap.data?.data() as Map<String, dynamic>?;
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

                            String statusText;
                            Color statusColor = colorScheme.onSurface
                                .withValues(alpha: 0.6);

                            if (isOnline) {
                              statusText = 'Đang hoạt động';
                              statusColor = const Color(0xFF10B981);
                            } else if (lastActive != null) {
                              final locale = Localizations.localeOf(
                                context,
                              ).languageCode;
                              statusText =
                                  'Hoạt động ${timeago.format(lastActive, locale: locale)}';
                            } else if (widget.otherUserFaculty.isNotEmpty) {
                              statusText = widget.otherUserFaculty;
                            } else {
                              statusText = 'Không trực tuyến';
                            }

                            return Row(
                              children: [
                                if (isOnline) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Flexible(
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isOnline
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: statusColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
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
                    return ChatMessageBubble(
                      message: message,
                      isMe: isMe,
                      isGroup: widget.isGroup,
                    );
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (prev, curr) => prev.typingUsers != curr.typingUsers,
            builder: (context, state) {
              return _buildTypingIndicator(state, currentUserId, colorScheme);
            },
          ),
          if (_selectedImage != null) _buildSelectedImagePreview(colorScheme),
          if (_selectedFile != null) _buildSelectedFilePreview(colorScheme),
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

  Widget _buildSelectedFilePreview(ColorScheme colorScheme) {
    final fileName = _selectedFileName ?? 'Tệp đính kèm';
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';
    final isPdf = ext == 'PDF';
    final isDoc = ext == 'DOC' || ext == 'DOCX';
    final isXls = ext == 'XLS' || ext == 'XLSX';
    final isPpt = ext == 'PPT' || ext == 'PPTX';
    final isTxt = ext == 'TXT';

    Color badgeColor = Colors.orange;
    IconData badgeIcon = Icons.insert_drive_file_rounded;
    if (isPdf) {
      badgeColor = Colors.red.shade600;
      badgeIcon = Icons.picture_as_pdf_rounded;
    } else if (isDoc) {
      badgeColor = const Color(0xFF2563EB);
      badgeIcon = Icons.description_rounded;
    } else if (isXls) {
      badgeColor = const Color(0xFF16A34A);
      badgeIcon = Icons.table_chart_rounded;
    } else if (isPpt) {
      badgeColor = const Color(0xFFEA580C);
      badgeIcon = Icons.slideshow_rounded;
    } else if (isTxt) {
      badgeColor = const Color(0xFF64748B);
      badgeIcon = Icons.text_snippet_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              badgeIcon,
              color: badgeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedFileSize ?? 'Tệp tài liệu',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              setState(() {
                _selectedFile = null;
                _selectedFileName = null;
                _selectedFileSize = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(
    ChatState state,
    String currentUserId,
    ColorScheme colorScheme,
  ) {
    final otherTyping = state.typingUsers.entries
        .where((e) => e.key != currentUserId && e.value == true)
        .toList();

    if (otherTyping.isEmpty) return const SizedBox.shrink();

    final typingName = widget.isGroup
        ? 'Thành viên trong nhóm'
        : widget.otherUserName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.primaryColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$typingName đang soạn tin nhắn...',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
          IconButton(
            icon: Icon(
              Icons.attach_file_rounded,
              color: AppTheme.accentColor(context),
              size: 24,
            ),
            tooltip: 'Gửi tệp tài liệu',
            onPressed: isSending ? null : _pickDocument,
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
                onChanged: _onTypingChanged,
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
