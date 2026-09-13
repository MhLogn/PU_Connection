import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final Map<String, String> participantFaculties;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;

  const ConversationEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.participantAvatars = const {},
    this.participantFaculties = const {},
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Sinh viên Phenikaa';
  }

  String getOtherParticipantAvatar(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantAvatars[otherId] ?? '';
  }

  String getOtherParticipantFaculty(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantFaculties[otherId] ?? '';
  }

  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  ConversationEntity copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    Map<String, String>? participantFaculties,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCounts,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      participantFaculties: participantFaculties ?? this.participantFaculties,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        participantNames,
        participantAvatars,
        participantFaculties,
        lastMessage,
        lastMessageSenderId,
        lastMessageAt,
        unreadCounts,
      ];
}
