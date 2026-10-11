import 'notification_type.dart';

class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String content;
  final NotificationType type;
  final String senderName;
  final String? senderAvatar;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? extraData;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.senderName,
    this.senderAvatar,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.extraData,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    NotificationType? type,
    String? senderName,
    String? senderAvatar,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      extraData: extraData ?? this.extraData,
    );
  }
}
