import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.messageId,
    required super.senderId,
    required super.senderName,
    super.senderAvatar = '',
    required super.content,
    super.imageUrl,
    required super.createdAt,
    super.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageModel(
      messageId: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Sinh viên Phenikaa',
      senderAvatar: map['senderAvatar'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MessageModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
