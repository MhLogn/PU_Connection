import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ConversationEntity> conversations;
  final List<MessageEntity> currentMessages;
  final String? activeConversationId;
  final Map<String, bool> typingUsers;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.currentMessages = const [],
    this.activeConversationId,
    this.typingUsers = const {},
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ConversationEntity>? conversations,
    List<MessageEntity>? currentMessages,
    String? activeConversationId,
    bool resetActiveConversation = false,
    Map<String, bool>? typingUsers,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      activeConversationId: resetActiveConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      typingUsers: typingUsers ?? this.typingUsers,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        currentMessages,
        activeConversationId,
        typingUsers,
        isSending,
        errorMessage,
      ];
}
