import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post_entity.dart';

class PostCard extends StatelessWidget {
  final PostEntity post;
  final String currentUserId;
  final VoidCallback onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onDeletePressed;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLikePressed,
    this.onCommentPressed,
    this.onSharePressed,
    this.onDeletePressed,
  });

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Hỏi bài':
      case 'Tìm nhóm':
        return AppTheme.accentColor(context);
      case 'Thảo luận':
        return AppTheme.violetColor(context);
      case 'Thông báo':
        return AppTheme.coralColor(context);
      case 'Tài liệu':
      default:
        return AppTheme.primaryColor(context);
    }
  }

  Color _getCategoryBg(BuildContext context, String category) {
    switch (category) {
      case 'Hỏi bài':
      case 'Tìm nhóm':
        return AppTheme.orangeContainer(context);
      default:
        return _getCategoryColor(context, category).withValues(
          alpha: AppTheme.isDark(context) ? 0.2 : 0.1,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isLiked = post.isLikedBy(currentUserId);
    final localeCode = Localizations.localeOf(context).languageCode;
    final formattedTime = post.createdAt != null
        ? timeago.format(post.createdAt!, locale: localeCode)
        : (localeCode == 'vi' ? 'Vừa xong' : 'Just now');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context, post.authorAvatar, post.authorName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppTheme.primaryColor(context),
                          ),
                          if (post.authorStudentId.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${post.authorStudentId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (post.authorFaculty.isNotEmpty) ...[
                            Text(
                              post.authorFaculty,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(' • ', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                          ],
                          Text(
                            formattedTime,
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryBg(context, post.category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(context, post.category),
                    ),
                  ),
                ),
                if (onDeletePressed != null) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: colorScheme.outline),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text('Xóa bài viết', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (post.subjectCode != null && post.subjectCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.blueContainer(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 13, color: AppTheme.primaryColor(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Môn: ${post.subjectCode}',
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
            const SizedBox(height: 10),
            Text(
              post.content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: post.tags.map((tag) {
                  return Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor(context).withValues(alpha: 0.9),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (post.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildAttachments(context, post.attachments),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isLiked ? AppTheme.accentColor(context) : colorScheme.onSurface.withValues(alpha: 0.6),
                  label: post.likeCount > 0 ? '${post.likeCount}' : l10n.like,
                  textColor: isLiked ? AppTheme.accentColor(context) : colorScheme.onSurface.withValues(alpha: 0.7),
                  onTap: onLikePressed,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: colorScheme.onSurface.withValues(alpha: 0.6),
                  label: post.commentCount > 0 ? '${post.commentCount}' : l10n.comment,
                  textColor: colorScheme.onSurface.withValues(alpha: 0.7),
                  onTap: onCommentPressed ?? () {},
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  iconColor: colorScheme.onSurface.withValues(alpha: 0.6),
                  label: l10n.share,
                  textColor: colorScheme.onSurface.withValues(alpha: 0.7),
                  onTap: onSharePressed ?? () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String avatarUrl, String name) {
    if (avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.blueContainer(context),
            child: Icon(Icons.person, size: 20, color: AppTheme.primaryColor(context)),
          ),
          errorWidget: (_, __, ___) => _buildInitialsAvatar(context, name),
        ),
      );
    }
    return _buildInitialsAvatar(context, name);
  }

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').last.substring(0, 1).toUpperCase()
        : 'P';
    final isDark = AppTheme.isDark(context);
    return CircleAvatar(
      radius: 20,
      backgroundColor: isDark ? AppTheme.darkBlueContainer : AppTheme.primaryBlue,
      child: Text(
        initials,
        style: TextStyle(
          color: isDark ? AppTheme.darkPrimaryBlue : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context, List<PostAttachment> attachments) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = attachments.where((a) => a.type == 'image').toList();
    final docs = attachments.where((a) => a.type != 'image').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(12),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: images.first.url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: images.first.url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 210,
                placeholder: (_, __) => Container(
                  height: 210,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        ...docs.map((doc) {
          final isPdf = doc.type == 'pdf';
          return InkWell(
            onTap: () {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.downloading} ${doc.name}...'),
                  backgroundColor: AppTheme.primaryColor(context),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPdf ? AppTheme.orangeContainer(context) : AppTheme.blueContainer(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPdf
                      ? AppTheme.accentColor(context).withValues(alpha: 0.35)
                      : AppTheme.primaryColor(context).withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                    color: isPdf ? AppTheme.accentColor(context) : AppTheme.primaryColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.download_rounded,
                    color: isPdf ? AppTheme.accentColor(context) : AppTheme.primaryColor(context),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 19, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeletePressed?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
