import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../../moderation/domain/entities/report_target_type.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
import '../cubit/feed_cubit.dart';

class PostCommentsBottomSheet extends StatefulWidget {
  final PostEntity post;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final String currentUserStudentId;
  final String currentUserFaculty;

  const PostCommentsBottomSheet({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar = '',
    this.currentUserStudentId = '',
    this.currentUserFaculty = '',
  });

  static void show(
    BuildContext context, {
    required PostEntity post,
    required String currentUserId,
    required String currentUserName,
    String currentUserAvatar = '',
    String currentUserStudentId = '',
    String currentUserFaculty = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FeedCubit>(),
        child: PostCommentsBottomSheet(
          post: post,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          currentUserAvatar: currentUserAvatar,
          currentUserStudentId: currentUserStudentId,
          currentUserFaculty: currentUserFaculty,
        ),
      ),
    );
  }

  @override
  State<PostCommentsBottomSheet> createState() =>
      _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends State<PostCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  CommentEntity? _replyingTo;

  final List<CommentEntity> _localComments = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentEntity comment) {
    setState(() {
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _toggleLikeComment(CommentEntity comment) async {
    final isLiked = comment.isLikedBy(widget.currentUserId);
    final updatedLikedUserIds = List<String>.from(comment.likedUserIds);
    if (isLiked) {
      updatedLikedUserIds.remove(widget.currentUserId);
    } else {
      updatedLikedUserIds.add(widget.currentUserId);
    }
    final updated = comment.copyWith(
      likedUserIds: updatedLikedUserIds,
      likeCount: isLiked
          ? (comment.likeCount > 0 ? comment.likeCount - 1 : 0)
          : comment.likeCount + 1,
    );
    final idx = _localComments.indexWhere(
      (c) => c.commentId == comment.commentId,
    );
    if (idx != -1) {
      setState(() {
        _localComments[idx] = updated;
      });
    }

    try {
      await context.read<FeedCubit>().toggleLikeComment(
        postId: widget.post.postId,
        commentId: comment.commentId,
        userId: widget.currentUserId,
        isCurrentlyLiked: isLiked,
      );
    } catch (_) {}
  }

  Future<void> _editComment(CommentEntity comment) async {
    final editController = TextEditingController(text: comment.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Chỉnh sửa bình luận',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung mới...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != comment.content) {
                Navigator.pop(ctx, newText);
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final idx = _localComments.indexWhere(
        (c) => c.commentId == comment.commentId,
      );
      if (idx != -1) {
        setState(() {
          _localComments[idx] = _localComments[idx].copyWith(
            content: result,
            isEdited: true,
          );
        });
      }
      try {
        await context.read<FeedCubit>().editComment(
          postId: widget.post.postId,
          commentId: comment.commentId,
          newContent: result,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật bình luận'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _deleteComment(CommentEntity comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa bình luận này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _localComments.removeWhere((c) => c.commentId == comment.commentId);
      });
      try {
        await context.read<FeedCubit>().deleteComment(
          postId: widget.post.postId,
          commentId: comment.commentId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa bình luận'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Tiền kiểm tra từ ngữ nhạy cảm trong bình luận
    if (sl.isRegistered<BadWordsFilterService>()) {
      final checkResult = sl<BadWordsFilterService>().check(text);
      if (!checkResult.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkResult.suggestionMessage ??
                  'Bình luận chứa từ ngữ không phù hợp với chuẩn mực văn hóa sinh viên.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSending = true);

    final commentDocId =
        'cmt_${DateTime.now().millisecondsSinceEpoch}_${widget.currentUserId.hashCode.abs()}';
    final replying = _replyingTo;
    final newComment = CommentEntity(
      commentId: commentDocId,
      authorId: widget.currentUserId,
      authorName: widget.currentUserName.isNotEmpty
          ? widget.currentUserName
          : 'Sinh viên Phenikaa',
      authorAvatar: widget.currentUserAvatar,
      authorStudentId: widget.currentUserStudentId,
      authorFaculty: widget.currentUserFaculty,
      content: text,
      createdAt: DateTime.now(),
      replyToCommentId: replying?.commentId,
      replyToAuthorName: replying?.authorName,
    );

    setState(() {
      _localComments.add(newComment);
    });

    try {
      await context.read<FeedCubit>().addComment(
        postId: widget.post.postId,
        commentId: commentDocId,
        authorId: widget.currentUserId,
        authorName: widget.currentUserName,
        authorAvatar: widget.currentUserAvatar,
        authorStudentId: widget.currentUserStudentId,
        authorFaculty: widget.currentUserFaculty,
        content: text,
        replyToCommentId: replying?.commentId,
        replyToAuthorName: replying?.authorName,
        replyToAuthorId: replying?.authorId,
      );

      if (mounted) {
        setState(() {
          _commentController.clear();
          _replyingTo = null;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Không thể gửi bình luận. Nội dung bình luận đã được lưu lại để bạn thử lại.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _localComments.removeWhere((c) => c.commentId == commentDocId);
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = AppTheme.isDark(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : const Color(0x10123B63),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: AppTheme.accentColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.comments_title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n.close,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.blueContainer(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(
                    context,
                    authorId: widget.post.authorId,
                    authorName: widget.post.authorName,
                    authorStudentId: widget.post.authorStudentId,
                    authorFaculty: widget.post.authorFaculty,
                    authorAvatar: widget.post.authorAvatar,
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.blueContainer(context),
                    backgroundImage:
                        AppTheme.imageProvider(widget.post.authorAvatar),
                    child: AppTheme.imageProvider(widget.post.authorAvatar) == null
                        ? Text(
                            widget.post.authorName.isNotEmpty
                                ? widget.post.authorName[0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor(context),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => _openAuthorProfile(
                                context,
                                authorId: widget.post.authorId,
                                authorName: widget.post.authorName,
                                authorStudentId: widget.post.authorStudentId,
                                authorFaculty: widget.post.authorFaculty,
                                authorAvatar: widget.post.authorAvatar,
                              ),
                              child: Text(
                                widget.post.authorName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppTheme.primaryColor(context),
                          ),
                          if (widget.post.authorStudentId.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• ${widget.post.authorStudentId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.orangeContainer(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.post.category,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.post.authorFaculty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.post.authorFaculty,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        widget.post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: StreamBuilder<List<CommentEntity>>(
              stream: context.read<FeedCubit>().getComments(widget.post.postId),
              builder: (context, snapshot) {
                final firestoreComments = snapshot.data ?? [];
                final Set<String> existingIds = firestoreComments
                    .map((c) => c.commentId)
                    .toSet();
                final allComments = [
                  ...firestoreComments,
                  ..._localComments.where(
                    (c) => !existingIds.contains(c.commentId),
                  ),
                ];

                if (allComments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 48,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.no_comments_yet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

                // Phân nhóm bình luận phân cấp Facebook: Root comments và Replies
                final allCommentIds = allComments.map((c) => c.commentId).toSet();
                final rootComments = allComments.where((c) {
                  final replyId = c.replyToCommentId;
                  return replyId == null || replyId.isEmpty || !allCommentIds.contains(replyId);
                }).toList();

                final Map<String, List<CommentEntity>> repliesMap = {};
                for (final c in allComments) {
                  final replyId = c.replyToCommentId;
                  if (replyId != null && replyId.isNotEmpty && allCommentIds.contains(replyId)) {
                    String effectiveRootId = replyId;
                    final parent = allComments.firstWhere(
                      (p) => p.commentId == replyId,
                      orElse: () => c,
                    );
                    if (parent.replyToCommentId != null &&
                        parent.replyToCommentId!.isNotEmpty &&
                        allCommentIds.contains(parent.replyToCommentId!)) {
                      effectiveRootId = parent.replyToCommentId!;
                    }
                    repliesMap.putIfAbsent(effectiveRootId, () => []).add(c);
                  }
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: rootComments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final rootComment = rootComments[index];
                    final replies = repliesMap[rootComment.commentId] ?? [];
                    return _buildCommentThread(
                      context,
                      rootComment,
                      replies,
                      isDark,
                      colorScheme,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 8 + keyboardBottom),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.blueContainer(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: AppTheme.primaryColor(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Đang trả lời ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                children: [
                                  TextSpan(
                                    text: '@${_replyingTo!.authorName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelReply,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.blueContainer(context),
                        backgroundImage:
                            AppTheme.imageProvider(widget.currentUserAvatar),
                        child: AppTheme.imageProvider(widget.currentUserAvatar) == null
                            ? Text(
                                widget.currentUserName.isNotEmpty
                                    ? widget.currentUserName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor(context),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? 'Trả lời @${_replyingTo!.authorName}...'
                                : '${l10n.comment}...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : AppTheme.borderLight,
                                width: 0.8,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : AppTheme.borderLight,
                                width: 0.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor(context),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSending ? null : _sendComment,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor(
                                  context,
                                ).withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAuthorProfile(
    BuildContext context, {
    required String authorId,
    required String authorName,
    String authorStudentId = '',
    String authorFaculty = '',
    String authorAvatar = '',
  }) {
    if (authorId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userId: authorId,
          userName: authorName,
          studentId: authorStudentId,
          faculty: authorFaculty,
          avatarUrl: authorAvatar,
        ),
      ),
    );
  }

  Widget _buildCommentThread(
    BuildContext context,
    CommentEntity rootComment,
    List<CommentEntity> replies,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(
          context,
          rootComment,
          isDark,
          colorScheme,
          isReply: false,
        ),
        if (replies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 6),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                        : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                children: replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildCommentItem(
                      context,
                      reply,
                      isDark,
                      colorScheme,
                      isReply: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentEntity comment,
    bool isDark,
    ColorScheme colorScheme, {
    bool isReply = false,
  }) {
    final effectiveAvatar = (comment.authorId == widget.currentUserId &&
            widget.currentUserAvatar.isNotEmpty)
        ? widget.currentUserAvatar
        : comment.authorAvatar;
    final effectiveName = (comment.authorId == widget.currentUserId &&
            widget.currentUserName.isNotEmpty)
        ? widget.currentUserName
        : comment.authorName;

    final initials = effectiveName.isNotEmpty
        ? effectiveName.trim().split(' ').last[0].toUpperCase()
        : 'P';
    final localeCode = Localizations.localeOf(context).languageCode;
    final timeStr = timeago.format(comment.createdAt, locale: localeCode);
    final isLiked = comment.isLikedBy(widget.currentUserId);
    final isAuthor = comment.authorId == widget.currentUserId;
    final avatarImg = AppTheme.imageProvider(effectiveAvatar);
    final avatarRadius = isReply ? 13.0 : 17.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openAuthorProfile(
            context,
            authorId: comment.authorId,
            authorName: effectiveName,
            authorStudentId: comment.authorStudentId,
            authorFaculty: comment.authorFaculty,
            authorAvatar: effectiveAvatar,
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppTheme.blueContainer(context),
            backgroundImage: avatarImg,
            child: avatarImg == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: isReply ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isReply ? 10 : 12,
                  vertical: isReply ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        )
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => _openAuthorProfile(
                                    context,
                                    authorId: comment.authorId,
                                    authorName: effectiveName,
                                    authorStudentId: comment.authorStudentId,
                                    authorFaculty: comment.authorFaculty,
                                    authorAvatar: effectiveAvatar,
                                  ),
                                  child: Text(
                                    effectiveName,
                                    style: TextStyle(
                                      fontSize: isReply ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (comment.authorFaculty.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '• ${comment.authorFaculty}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            if (comment.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(đã sửa)',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ],
                            if (!isAuthor) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  ReportBottomSheet.show(
                                    context,
                                    targetId: comment.commentId,
                                    targetType: ReportTargetType.comment,
                                    targetAuthorId: comment.authorId,
                                    targetAuthorName: effectiveName,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.flag_outlined,
                                    size: 13,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (comment.replyToAuthorName != null &&
                        comment.replyToAuthorName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 12,
                              color: AppTheme.primaryColor(context),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Trả lời @${comment.replyToAuthorName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 4, bottom: 2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleLikeComment(comment),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 14,
                              color: isLiked
                                  ? Colors.red
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likeCount > 0
                                  ? '${comment.likeCount}'
                                  : 'Thích',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isLiked
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isLiked
                                    ? Colors.red
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.65,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _startReply(comment),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trả lời',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _editComment(comment),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'Sửa',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _deleteComment(comment),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'Xóa',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
