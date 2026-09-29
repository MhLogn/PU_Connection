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
  final bool isGroup;
  final String groupName;
  final String groupAvatar;
  final String adminId;

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
    this.isGroup = false,
    this.groupName = '',
    this.groupAvatar = '',
    this.adminId = '',
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

  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupName.isNotEmpty ? groupName : 'Nhóm trò chuyện';
    }
    return getOtherParticipantName(currentUserId);
  }

  String getDisplayAvatar(String currentUserId) {
    if (isGroup) {
      return groupAvatar;
    }
    return getOtherParticipantAvatar(currentUserId);
  }

  String getDisplaySubtitle(String currentUserId) {
    if (isGroup) {
      return '${participantIds.length} thành viên';
    }
    return getOtherParticipantFaculty(currentUserId);
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
    bool? isGroup,
    String? groupName,
    String? groupAvatar,
    String? adminId,
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
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      adminId: adminId ?? this.adminId,
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
        isGroup,
        groupName,
        groupAvatar,
        adminId,
      ];
}
