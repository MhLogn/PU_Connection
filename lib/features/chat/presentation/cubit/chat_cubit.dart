import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final CloudinaryService _cloudinaryService;
  StreamSubscription<List<ConversationEntity>>? _convSubscription;
  StreamSubscription<List<MessageEntity>>? _msgSubscription;

  ChatCubit({
    required ChatRepository chatRepository,
    CloudinaryService? cloudinaryService,
  })  : _chatRepository = chatRepository,
        _cloudinaryService = cloudinaryService ??
            (sl.isRegistered<CloudinaryService>()
                ? sl<CloudinaryService>()
                : CloudinaryService()),
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
        .listen(
      (messages) {
        emit(state.copyWith(currentMessages: messages));
      },
      onError: (error) {
        // Silently handle or log if disconnected on signout
      },
    );

    _chatRepository.markAsRead(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
  }

  void closeCurrentConversation() {
    _msgSubscription?.cancel();
    _msgSubscription = null;
    emit(state.copyWith(
      resetActiveConversation: true,
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
    File? imageFile,
    required List<String> participantIds,
  }) async {
    if (content.trim().isEmpty && imageUrl == null && imageFile == null) return;

    emit(state.copyWith(isSending: true));

    try {
      String? resolvedImageUrl = imageUrl;
      if (imageFile != null) {
        resolvedImageUrl = await _cloudinaryService.uploadImage(imageFile);
      }

      final msg = MessageEntity(
        messageId: '',
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content.trim(),
        imageUrl: resolvedImageUrl,
        createdAt: DateTime.now(),
        isRead: false,
      );

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

  Future<String> createGroupConversation({
    required String groupName,
    String groupAvatar = '',
    required String creatorId,
    required String creatorName,
    String creatorAvatar = '',
    String creatorFaculty = '',
    required List<Map<String, String>> members,
  }) async {
    emit(state.copyWith(isSending: true));
    try {
      final convId = await _chatRepository.createGroupConversation(
        groupName: groupName,
        groupAvatar: groupAvatar,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorAvatar: creatorAvatar,
        creatorFaculty: creatorFaculty,
        members: members,
      );
      emit(state.copyWith(isSending: false));
      openConversation(convId, creatorId);
      return convId;
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: 'Không thể tạo nhóm: $e',
      ));
      rethrow;
    }
  }

  Future<void> leaveGroup({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _chatRepository.leaveGroup(
        conversationId: conversationId,
        userId: userId,
      );
      closeCurrentConversation();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể rời nhóm: $e'));
      rethrow;
    }
  }

  Future<void> updateGroupInfo({
    required String conversationId,
    String? groupName,
    String? groupAvatar,
  }) async {
    try {
      await _chatRepository.updateGroupInfo(
        conversationId: conversationId,
        groupName: groupName,
        groupAvatar: groupAvatar,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể cập nhật thông tin nhóm: $e'));
      rethrow;
    }
  }

  void reset() {
    _convSubscription?.cancel();
    _convSubscription = null;
    _msgSubscription?.cancel();
    _msgSubscription = null;
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _convSubscription?.cancel();
    _msgSubscription?.cancel();
    return super.close();
  }
}
