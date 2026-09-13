import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const MessageEntity({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  MessageEntity copyWith({
    String? messageId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MessageEntity(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
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
        createdAt,
        isRead,
      ];
}
