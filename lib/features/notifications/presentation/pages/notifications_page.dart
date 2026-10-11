import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../events/presentation/pages/events_page.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/in_app_notifications_cubit.dart';
import '../cubit/in_app_notifications_state.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_item_tile.dart';

class NotificationsPage extends StatelessWidget {
  final bool isBottomSheet;

  const NotificationsPage({super.key, this.isBottomSheet = false});

  static Future<void> showAsBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NotificationsPage(isBottomSheet: true),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationEntity notif) {
    // Đánh dấu đã đọc
    if (!notif.isRead) {
      context.read<InAppNotificationsCubit>().markAsRead(notif.id);
    }

    final route = notif.actionRoute;
    if (route == null || route.isEmpty) {
      _showDetailDialog(context, notif);
      return;
    }

    if (route == 'events') {
      if (isBottomSheet) Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventsPage()),
      );
    } else if (route.startsWith('user:')) {
      final targetUserId = route.replaceFirst('user:', '');
      if (isBottomSheet) Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(
            userId: targetUserId,
            userName: notif.senderName,
            avatarUrl: notif.senderAvatar ?? '',
          ),
        ),
      );
    } else {
      _showDetailDialog(context, notif);
    }
  }

  void _showDetailDialog(BuildContext context, NotificationEntity notif) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = notif.type.defaultColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(notif.type.icon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                notif.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${notif.createdAt.day.toString().padLeft(2, '0')}/${notif.createdAt.month.toString().padLeft(2, '0')}/${notif.createdAt.year} ${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<InAppNotificationsCubit, InAppNotificationsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colorScheme.error,
            ),
          );
          context.read<InAppNotificationsCubit>().clearMessage();
        } else if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
          context.read<InAppNotificationsCubit>().clearMessage();
        }
      },
      builder: (context, state) {
        final notifications = state.filteredNotifications;
        final unreadCount = state.unreadCount;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: colorScheme.surface,
            leading: isBottomSheet
                ? IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    onPressed: () => Navigator.pop(context),
                  )
                : const BackButton(),
            title: Row(
              children: [
                Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () {
                    context.read<InAppNotificationsCubit>().markAllAsRead();
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text(
                    'Đọc tất cả',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Bộ lọc phân loại
              NotificationFilterChips(
                selectedFilter: state.selectedFilter,
                state: state,
                onFilterSelected: (filter) {
                  context.read<InAppNotificationsCubit>().setFilter(filter);
                },
              ),
              const Divider(height: 1),

              // Danh sách thông báo
              Expanded(
                child: state.status == NotificationsStatus.loading &&
                        state.notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                        ? _buildEmptyState(context, state)
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 68),
                            itemBuilder: (context, index) {
                              final notif = notifications[index];
                              return NotificationItemTile(
                                notification: notif,
                                onTap: () => _handleNotificationTap(context, notif),
                                onDismissed: () {
                                  context
                                      .read<InAppNotificationsCubit>()
                                      .deleteNotification(notif.id);
                                },
                                onMarkAsRead: () {
                                  context
                                      .read<InAppNotificationsCubit>()
                                      .markAsRead(notif.id);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, InAppNotificationsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFiltered = state.selectedFilter != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? state.selectedFilter!.icon
                    : Icons.notifications_none_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Chưa có thông báo ${state.selectedFilter!.displayName.toLowerCase()}'
                  : 'Không có thông báo nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Khi có thông báo mới thuộc danh mục này, bạn sẽ nhận được tại đây.'
                  : 'Bạn đã xem hết các thông báo từ trường Đại học Phenikaa và bạn bè.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  context.read<InAppNotificationsCubit>().setFilter(null);
                },
                child: const Text('Xem tất cả thông báo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
