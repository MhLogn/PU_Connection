import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blocked_user_entity.dart';

class BlockedUserModel extends BlockedUserEntity {
  const BlockedUserModel({
    required super.userId,
    super.userName,
    super.userAvatar,
    super.userFaculty,
    super.blockedAt,
  });

  factory BlockedUserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? blocked;
    final rawBlocked = map['blockedAt'];
    if (rawBlocked is Timestamp) {
      blocked = rawBlocked.toDate();
    } else if (rawBlocked is String) {
      blocked = DateTime.tryParse(rawBlocked);
    }

    return BlockedUserModel(
      userId: id,
      userName: map['userName'] as String? ?? '',
      userAvatar: map['userAvatar'] as String? ?? '',
      userFaculty: map['userFaculty'] as String? ?? '',
      blockedAt: blocked,
    );
  }

  factory BlockedUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BlockedUserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userFaculty': userFaculty,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
