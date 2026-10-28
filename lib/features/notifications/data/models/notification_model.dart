import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.content,
    required super.type,
    required super.senderName,
    super.senderAvatar,
    required super.createdAt,
    super.isRead = false,
    super.actionRoute,
    super.extraData,
  });

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      type: entity.type,
      senderName: entity.senderName,
      senderAvatar: entity.senderAvatar,
      createdAt: entity.createdAt,
      isRead: entity.isRead,
      actionRoute: entity.actionRoute,
      extraData: entity.extraData,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final rawContent = map['content'] as String?;
    final rawBody = map['body'] as String?;
    final resolvedContent = (rawContent != null && rawContent.isNotEmpty)
        ? rawContent
        : (rawBody ?? '');

    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: resolvedContent,
      type: NotificationType.fromString(map['type'] as String?),
      senderName: map['senderName'] as String? ?? 'Phenikaa University',
      senderAvatar: map['senderAvatar'] as String?,
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
      actionRoute: map['actionRoute'] as String?,
      extraData: map['extraData'] is Map
          ? Map<String, dynamic>.from(map['extraData'] as Map)
          : null,
    );
  }

  factory NotificationModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'type': type.name,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'actionRoute': actionRoute,
      'extraData': extraData,
    };
  }
}
