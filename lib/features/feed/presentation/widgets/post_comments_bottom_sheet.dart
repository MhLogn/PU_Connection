import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
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
  State<PostCommentsBottomSheet> createState() => _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends State<PostCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<CommentEntity> _localComments = [];

  @override
  void initState() {
    super.initState();
    if (widget.post.commentCount > 0) {
      _localComments.addAll([
        CommentEntity(
          commentId: 'init_1',
          authorId: 'stu_demo_1',
          authorName: 'Nguyễn Hoàng Nam',
          authorFaculty: 'Công nghệ thông tin',
          authorStudentId: '22010214',
          content: 'Cảm ơn bạn đã chia sẻ tài liệu rất chi tiết, đúng phần mình đang cần ôn thi!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        CommentEntity(
          commentId: 'init_2',
          authorId: 'stu_demo_2',
          authorName: 'Lê Thảo My',
          authorFaculty: widget.post.authorFaculty.isNotEmpty
              ? widget.post.authorFaculty
              : 'Kinh tế & QTKD',
          authorStudentId: '23010512',
          content: 'Cho mình xin thêm phần bài tập trắc nghiệm chương 3 với được không ạ?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final newComment = CommentEntity(
      commentId: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: widget.currentUserId,
      authorName: widget.currentUserName.isNotEmpty ? widget.currentUserName : 'Sinh viên Phenikaa',
      authorAvatar: widget.currentUserAvatar,
      authorStudentId: widget.currentUserStudentId,
      authorFaculty: widget.currentUserFaculty,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _localComments.add(newComment);
      _commentController.clear();
    });

    try {
      await context.read<FeedCubit>().addComment(
            postId: widget.post.postId,
            authorId: widget.currentUserId,
            authorName: widget.currentUserName,
            authorAvatar: widget.currentUserAvatar,
            authorStudentId: widget.currentUserStudentId,
            authorFaculty: widget.currentUserFaculty,
            content: text,
          );
    } catch (_) {}

    if (mounted) {
      setState(() => _isSending = false);
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -5),
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
                      '${l10n.comments_title} (${widget.post.commentCount + _localComments.length - (widget.post.commentCount > 0 ? 2 : 0)})',
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor(context),
                  child: Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black87 : Colors.white,
                    ),
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
                            child: Text(
                              widget.post.authorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.orangeContainer(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.post.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                final Set<String> existingIds = firestoreComments.map((c) => c.commentId).toSet();
                final allComments = [
                  ...firestoreComments,
                  ..._localComments.where((c) => !existingIds.contains(c.commentId)),
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
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allComments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final comment = allComments[index];
                    return _buildCommentItem(context, comment, isDark, colorScheme);
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
                top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.blueContainer(context),
                    child: Text(
                      widget.currentUserName.isNotEmpty
                          ? widget.currentUserName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: '${l10n.comment}...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: AppTheme.accentColor(context),
                          ),
                    tooltip: l10n.comment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentEntity comment,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final initials = comment.authorName.isNotEmpty
        ? comment.authorName.trim().split(' ').last[0].toUpperCase()
        : 'P';
    final localeCode = Localizations.localeOf(context).languageCode;
    final timeStr = timeago.format(comment.createdAt, locale: localeCode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppTheme.blueContainer(context),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor(context),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
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
                            child: Text(
                              comment.authorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.authorFaculty.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${comment.authorFaculty}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
