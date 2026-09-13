import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    super.participantAvatars = const {},
    super.participantFaculties = const {},
    super.lastMessage = '',
    super.lastMessageSenderId = '',
    super.lastMessageAt,
    super.unreadCounts = const {},
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    Map<String, String> parseStringMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {};
    }

    Map<String, int> parseIntMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
      }
      return {};
    }

    final participantIdsRaw = map['participantIds'] as List<dynamic>? ?? [];
    final participantIds = participantIdsRaw.map((e) => e.toString()).toList();

    return ConversationModel(
      id: id,
      participantIds: participantIds,
      participantNames: parseStringMap(map['participantNames']),
      participantAvatars: parseStringMap(map['participantAvatars']),
      participantFaculties: parseStringMap(map['participantFaculties']),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: parseDate(map['lastMessageAt']),
      unreadCounts: parseIntMap(map['unreadCounts']),
    );
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ConversationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'participantFaculties': participantFaculties,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }
}
