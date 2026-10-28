import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/feed_cubit.dart';

class SharePostBottomSheet extends StatefulWidget {
  final PostEntity post;
  final UserEntity currentUser;

  const SharePostBottomSheet({
    super.key,
    required this.post,
    required this.currentUser,
  });

  static Future<void> show(
    BuildContext context, {
    required PostEntity post,
    required UserEntity currentUser,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostBottomSheet(
        post: post,
        currentUser: currentUser,
      ),
    );
  }

  @override
  State<SharePostBottomSheet> createState() => _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends State<SharePostBottomSheet> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSharing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handleShareNow() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await context.read<FeedCubit>().sharePost(
            originalPost: widget.post,
            authorId: widget.currentUser.uid,
            authorName: widget.currentUser.displayName,
            authorAvatar: widget.currentUser.avatarUrl,
            authorStudentId: widget.currentUser.studentId,
            authorFaculty: widget.currentUser.faculty,
            caption: _captionController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ bài viết lên bảng tin của bạn! 🎉'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chia sẻ bài viết: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(
        text: '${widget.post.authorName}: ${widget.post.content}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết và nội dung bài viết!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String url, String name, double radius) {
    final effectiveName = name.trim().isNotEmpty ? name.trim() : 'P';
    final initial = effectiveName.split(' ').last.substring(0, 1).toUpperCase();
    final imgProvider = AppTheme.imageProvider(url);

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.blueContainer(context),
      backgroundImage: imgProvider,
      child: imgProvider == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor(context),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final localeCode = Localizations.localeOf(context).languageCode;
    final postTime = widget.post.createdAt != null
        ? timeago.format(widget.post.createdAt!, locale: localeCode)
        : 'Vừa xong';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + keyboardBottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : const Color(0x15123B63),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạt modal
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Tiêu đề & nút đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chia sẻ bài viết',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 16),

            // Người dùng chia sẻ
            Row(
              children: [
                _buildAvatar(
                  context,
                  widget.currentUser.avatarUrl,
                  widget.currentUser.displayName,
                  20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUser.displayName.isNotEmpty
                          ? widget.currentUser.displayName
                          : 'Bạn',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.blueContainer(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: AppTheme.primaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bảng tin công khai',
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
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ô nhập caption bài chia sẻ
            TextField(
              controller: _captionController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Hãy nói gì đó về bài viết này...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),

            // Khung trích dẫn bài viết gốc (Quote Card)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : const Color(0xFFE5E7EB),
                ),
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
                    : const Color(0xFFF9FAFB),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(
                        context,
                        widget.post.authorAvatar,
                        widget.post.authorName,
                        15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              postTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Các nút hành động
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Sao chép liên kết'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSharing ? null : _handleShareNow,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(_isSharing ? 'Đang chia sẻ...' : 'Chia sẻ ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
