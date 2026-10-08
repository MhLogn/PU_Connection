import 'package:equatable/equatable.dart';

class FriendRequestEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String senderFaculty;
  final String receiverId;
  final String receiverName;
  final DateTime? createdAt;
  final String status; // 'pending' | 'accepted' | 'declined'

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    this.senderName = '',
    this.senderAvatar = '',
    this.senderFaculty = '',
    required this.receiverId,
    this.receiverName = '',
    this.createdAt,
    this.status = 'pending',
  });

  FriendRequestEntity copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? senderFaculty,
    String? receiverId,
    String? receiverName,
    DateTime? createdAt,
    String? status,
  }) {
    return FriendRequestEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderFaculty: senderFaculty ?? this.senderFaculty,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderAvatar,
        senderFaculty,
        receiverId,
        receiverName,
        createdAt,
        status,
      ];
}
