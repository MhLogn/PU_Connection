import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/datasources/phenikaa_student_directory.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/post_entity.dart';

class PostCard extends StatelessWidget {
  final PostEntity post;
  final String currentUserId;
  final VoidCallback onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLikePressed,
    this.onCommentPressed,
    this.onSharePressed,
    this.onDeletePressed,
    this.onChatPressed,
    this.onAuthorTap,
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

  void _openAuthorProfile(BuildContext context, String resolvedStudentId, String resolvedFaculty) {
    if (onAuthorTap != null) {
      onAuthorTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userId: post.authorId,
          userName: post.authorName,
          studentId: resolvedStudentId,
          faculty: resolvedFaculty,
          avatarUrl: post.authorAvatar,
        ),
      ),
    );
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

    final resolvedStudentId = post.authorStudentId.isNotEmpty
        ? post.authorStudentId
        : (PhenikaaStudentDirectory.defaultStudents
            .where((s) => s.fullName.toLowerCase() == post.authorName.toLowerCase())
            .firstOrNull
            ?.studentId ?? '');
    final resolvedFaculty = post.authorFaculty.isNotEmpty
        ? post.authorFaculty
        : (PhenikaaStudentDirectory.defaultStudents
            .where((s) => s.fullName.toLowerCase() == post.authorName.toLowerCase())
            .firstOrNull
            ?.faculty ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context)
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0284C7).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Thông tin người đăng (Rộng rãi, không bị che mất) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(context, resolvedStudentId, resolvedFaculty),
                  child: _buildAvatar(context, post.authorAvatar, post.authorName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openAuthorProfile(context, resolvedStudentId, resolvedFaculty),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dòng 1: Họ và tên người đăng + Huy hiệu xác minh sinh viên Phenikaa
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppTheme.primaryColor(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Dòng 2: Mã số sinh viên (Badge) & Khoa / Viện đào tạo
                        Row(
                          children: [
                            if (resolvedStudentId.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  resolvedStudentId,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                              if (resolvedFaculty.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                            ],
                            if (resolvedFaculty.isNotEmpty)
                              Flexible(
                                child: Text(
                                  resolvedFaculty,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.primaryColor(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Dòng 3: Thời gian đăng bài
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Nút tùy chọn (Menu 3 chấm nếu là chủ bài viết, icon chat nếu là người khác)
                if (onDeletePressed != null) ...[
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, size: 22, color: colorScheme.outline),
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
                ] else if (onChatPressed != null) ...[
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppTheme.primaryColor(context)),
                    tooltip: 'Nhắn tin cho tác giả',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onChatPressed,
                  ),
                ],
              ],
            ),

            // --- METADATA PILLS: Thẻ phân loại & Mã môn học ---
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tag Phân loại (Hỏi bài, Thảo luận, Tìm nhóm, Tài liệu)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: _getCategoryBg(context, post.category),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(context, post.category).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(context, post.category),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        post.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(context, post.category),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tag Mã môn học (nếu có)
                if (post.subjectCode != null && post.subjectCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 12, color: AppTheme.primaryColor(context)),
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
            ),
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
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.oceanToOrangeGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.blueContainer(context),
                    child: Icon(Icons.person, size: 19, color: AppTheme.primaryColor(context)),
                  ),
                  errorWidget: (_, __, ___) => _buildInitialsAvatar(context, name),
                )
              : _buildInitialsAvatar(context, name),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').last.substring(0, 1).toUpperCase()
        : 'P';
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.oceanGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
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
