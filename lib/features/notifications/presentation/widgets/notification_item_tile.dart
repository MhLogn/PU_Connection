import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationItemTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback onMarkAsRead;

  const NotificationItemTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
    required this.onMarkAsRead,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRead = notification.isRead;
    final typeColor = notification.type.defaultColor;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.error,
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
      ),
      child: Material(
        color: isRead
            ? Colors.transparent
            : colorScheme.primary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar hoặc Icon loại thông báo
                _buildLeadingAvatar(context, typeColor),
                const SizedBox(width: 12),

                // Nội dung chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Sender & Badge & Time
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    notification.senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: typeColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    notification.type.displayName,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Tiêu đề thông báo
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Nội dung thông báo
                      Text(
                        notification.content,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isRead
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Popup menu tùy chọn
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'read') {
                      onMarkAsRead();
                    } else if (val == 'delete') {
                      onDismissed();
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!isRead)
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Đánh dấu đã đọc', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa thông báo', style: TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar(BuildContext context, Color typeColor) {
    if (notification.senderAvatar != null &&
        notification.senderAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(notification.senderAvatar!),
        backgroundColor: typeColor.withValues(alpha: 0.1),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        notification.type.icon,
        color: typeColor,
        size: 22,
      ),
    );
  }
}
