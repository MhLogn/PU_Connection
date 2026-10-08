import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/friend_request_entity.dart';

class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.id,
    required super.senderId,
    super.senderName,
    super.senderAvatar,
    super.senderFaculty,
    required super.receiverId,
    super.receiverName,
    super.createdAt,
    super.status,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? created;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    return FriendRequestModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderAvatar: map['senderAvatar'] as String? ?? '',
      senderFaculty: map['senderFaculty'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      createdAt: created,
      status: map['status'] as String? ?? 'pending',
    );
  }

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequestModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'senderFaculty': senderFaculty,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
