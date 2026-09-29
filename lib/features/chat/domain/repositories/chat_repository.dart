import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<ConversationEntity>> getConversationsStream(String currentUserId);
  Stream<List<MessageEntity>> getMessagesStream(String conversationId);
  Future<void> sendMessage({
    required String conversationId,
    required MessageEntity message,
    required List<String> participantIds,
  });
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String otherUserId,
    required String otherUserName,
    required String otherUserAvatar,
    required String otherUserFaculty,
  });
  Future<String> createGroupConversation({
    required String groupName,
    String groupAvatar = '',
    required String creatorId,
    required String creatorName,
    String creatorAvatar = '',
    String creatorFaculty = '',
    required List<Map<String, String>> members,
  });
  Future<void> leaveGroup({
    required String conversationId,
    required String userId,
  });
  Future<void> updateGroupInfo({
    required String conversationId,
    String? groupName,
    String? groupAvatar,
  });
  Future<void> markAsRead({
    required String conversationId,
    required String currentUserId,
  });
}
