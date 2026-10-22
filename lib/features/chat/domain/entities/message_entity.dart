import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;

  const MessageEntity({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = true,
  });

  MessageEntity copyWith({
    String? messageId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? fileSize,
    DateTime? createdAt,
    bool? isRead,
    bool? isDelivered,
  }) {
    return MessageEntity(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  @override
  List<Object?> get props => [
        messageId,
        senderId,
        senderName,
        senderAvatar,
        content,
        imageUrl,
        fileUrl,
        fileName,
        fileType,
        fileSize,
        createdAt,
        isRead,
        isDelivered,
      ];
}
