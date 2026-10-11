import '../entities/notification_entity.dart';

abstract class InAppNotificationRepository {
  /// Theo dõi danh sách thông báo theo thời gian thực của sinh viên
  Stream<List<NotificationEntity>> watchNotifications(String userId);

  /// Lấy danh sách thông báo một lần
  Future<List<NotificationEntity>> getNotifications(String userId);

  /// Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(String userId, String notificationId);

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead(String userId);

  /// Xóa 1 thông báo
  Future<void> deleteNotification(String userId, String notificationId);

  /// Gửi hoặc ghi nhận thông báo mới cho người dùng
  Future<void> sendNotification(NotificationEntity notification);
}
