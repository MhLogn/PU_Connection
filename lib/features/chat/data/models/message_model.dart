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
    super.fileUrl,
    super.fileName,
    super.fileType,
    super.fileSize,
    required super.createdAt,
    super.isRead = false,
    super.isDelivered = true,
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
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String?,
      fileType: map['fileType'] as String?,
      fileSize: map['fileSize'] as String?,
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
      isDelivered: map['isDelivered'] as bool? ?? true,
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
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isDelivered': isDelivered,
    };
  }
}
