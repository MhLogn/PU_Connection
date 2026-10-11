import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class InAppNotificationsState {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final NotificationType? selectedFilter;
  final String? errorMessage;
  final String? successMessage;

  const InAppNotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.selectedFilter,
    this.errorMessage,
    this.successMessage,
  });

  /// Danh sách thông báo sau khi lọc theo tab hiện tại
  List<NotificationEntity> get filteredNotifications {
    if (selectedFilter == null) return notifications;
    return notifications.where((n) => n.type == selectedFilter).toList();
  }

  /// Tổng số thông báo chưa đọc trong toàn bộ danh sách
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Đếm số thông báo theo từng loại để hiển thị badge trên các chip lọc
  int countByType(NotificationType type) {
    return notifications.where((n) => n.type == type).length;
  }

  InAppNotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    NotificationType? Function()? selectedFilter,
    String? errorMessage,
    String? successMessage,
  }) {
    return InAppNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      selectedFilter: selectedFilter != null ? selectedFilter() : this.selectedFilter,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
