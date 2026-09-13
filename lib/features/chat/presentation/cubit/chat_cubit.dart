import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ConversationEntity>>? _convSubscription;
  StreamSubscription<List<MessageEntity>>? _msgSubscription;

  ChatCubit({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState());

  void initConversations(String currentUserId) {
    if (currentUserId.isEmpty) return;
    _convSubscription?.cancel();

    emit(state.copyWith(status: ChatStatus.loading));

    _convSubscription = _chatRepository
        .getConversationsStream(currentUserId)
        .listen(
      (conversations) {
        emit(state.copyWith(
          status: ChatStatus.loaded,
          conversations: conversations,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void openConversation(String conversationId, String currentUserId) {
    _msgSubscription?.cancel();
    emit(state.copyWith(
      activeConversationId: conversationId,
      currentMessages: [],
    ));

    _msgSubscription = _chatRepository
        .getMessagesStream(conversationId)
        .listen((messages) {
      emit(state.copyWith(currentMessages: messages));
    });

    _chatRepository.markAsRead(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
  }

  void closeCurrentConversation() {
    _msgSubscription?.cancel();
    _msgSubscription = null;
    emit(state.copyWith(
      activeConversationId: null,
      currentMessages: [],
    ));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String senderAvatar = '',
    required String content,
    String? imageUrl,
    required List<String> participantIds,
  }) async {
    if (content.trim().isEmpty && imageUrl == null) return;

    emit(state.copyWith(isSending: true));

    final msg = MessageEntity(
      messageId: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isRead: false,
    );

    try {
      await _chatRepository.sendMessage(
        conversationId: conversationId,
        message: msg,
        participantIds: participantIds,
      );
      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: 'Không thể gửi tin nhắn: $e',
      ));
    }
  }

  Future<String> startDirectChat({
    required String currentUserId,
    required String currentUserName,
    String currentUserAvatar = '',
    String currentUserFaculty = '',
    required String otherUserId,
    required String otherUserName,
    String otherUserAvatar = '',
    String otherUserFaculty = '',
  }) async {
    final convId = await _chatRepository.getOrCreateConversation(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserAvatar: currentUserAvatar,
      currentUserFaculty: currentUserFaculty,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      otherUserFaculty: otherUserFaculty,
    );

    openConversation(convId, currentUserId);
    return convId;
  }

  @override
  Future<void> close() {
    _convSubscription?.cancel();
    _msgSubscription?.cancel();
    return super.close();
  }
}
