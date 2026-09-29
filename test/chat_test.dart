import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/cloudinary_service.dart';
import 'package:pu_connection/features/chat/domain/entities/conversation_entity.dart';
import 'package:pu_connection/features/chat/domain/entities/message_entity.dart';
import 'package:pu_connection/features/chat/data/models/conversation_model.dart';
import 'package:pu_connection/features/chat/data/models/message_model.dart';
import 'package:pu_connection/features/chat/domain/repositories/chat_repository.dart';
import 'package:pu_connection/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:pu_connection/features/chat/presentation/cubit/chat_state.dart';

class MockCloudinaryService extends CloudinaryService {
  @override
  Future<String?> uploadImage(dynamic file, {String folder = 'pu_connection/images'}) async {
    return 'https://cloudinary.com/test_image.jpg';
  }
}

class MockChatRepository implements ChatRepository {
  final List<ConversationEntity> _conversations = [
    ConversationEntity(
      id: 'userA_userB',
      participantIds: const ['userA', 'userB'],
      participantNames: const {
        'userA': 'Nguyễn Văn An',
        'userB': 'Trần Thị Mai',
      },
      participantFaculties: const {
        'userA': 'CNTT',
        'userB': 'Dược - Y',
      },
      lastMessage: 'Chào bạn, cho mình xin tài liệu nhé!',
      lastMessageSenderId: 'userB',
      lastMessageAt: DateTime(2026, 1, 1),
      unreadCounts: const {'userA': 1, 'userB': 0},
    ),
  ];

  final Map<String, List<MessageEntity>> _messages = {
    'userA_userB': [
      MessageEntity(
        messageId: 'msg_1',
        senderId: 'userB',
        senderName: 'Trần Thị Mai',
        content: 'Chào bạn, cho mình xin tài liệu nhé!',
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  };

  @override
  Stream<List<ConversationEntity>> getConversationsStream(String currentUserId) {
    return Stream.value(_conversations);
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String conversationId) {
    return Stream.value(_messages[conversationId] ?? []);
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required MessageEntity message,
    required List<String> participantIds,
  }) async {
    final list = _messages[conversationId] ?? [];
    list.add(message);
    _messages[conversationId] = list;
  }

  @override
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String otherUserId,
    required String otherUserName,
    required String otherUserAvatar,
    required String otherUserFaculty,
  }) async {
    final sorted = [currentUserId, otherUserId]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<String> createGroupConversation({
    required String groupName,
    String groupAvatar = '',
    required String creatorId,
    required String creatorName,
    String creatorAvatar = '',
    String creatorFaculty = '',
    required List<Map<String, String>> members,
  }) async {
    final convId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final pIds = [creatorId, ...members.map((m) => m['id'] ?? '')];
    final conv = ConversationEntity(
      id: convId,
      participantIds: pIds,
      participantNames: {
        creatorId: creatorName,
        for (var m in members) m['id'] ?? '': m['name'] ?? '',
      },
      isGroup: true,
      groupName: groupName,
      groupAvatar: groupAvatar,
      adminId: creatorId,
      lastMessage: '$creatorName đã tạo nhóm "$groupName"',
      lastMessageSenderId: creatorId,
      lastMessageAt: DateTime.now(),
    );
    _conversations.add(conv);
    return convId;
  }

  @override
  Future<void> leaveGroup({
    required String conversationId,
    required String userId,
  }) async {
    _conversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<void> updateGroupInfo({
    required String conversationId,
    String? groupName,
    String? groupAvatar,
  }) async {}

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {}
}

void main() {
  group('MessageModel & MessageEntity Tests', () {
    test('MessageModel converts to and from Map correctly', () {
      final msg = MessageModel(
        messageId: 'msg_100',
        senderId: 'user_1',
        senderName: 'Hà Mạnh Long',
        content: 'Hôm nay học phòng mấy bạn nhỉ?',
        imageUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2026, 2, 10, 8, 30),
        isRead: true,
      );

      final map = msg.toMap();
      expect(map['senderId'], 'user_1');
      expect(map['senderName'], 'Hà Mạnh Long');
      expect(map['content'], 'Hôm nay học phòng mấy bạn nhỉ?');
      expect(map['imageUrl'], 'https://example.com/photo.jpg');
      expect(map['isRead'], true);

      final fromMap = MessageModel.fromMap(map, 'msg_100');
      expect(fromMap.messageId, 'msg_100');
      expect(fromMap.senderId, msg.senderId);
      expect(fromMap.content, msg.content);
      expect(fromMap.imageUrl, 'https://example.com/photo.jpg');
      expect(fromMap.isRead, msg.isRead);
    });

    test('MessageEntity copyWith updates specified fields', () {
      final entity = MessageEntity(
        messageId: '1',
        senderId: 'userA',
        senderName: 'Name A',
        content: 'Original',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = entity.copyWith(content: 'Modified', isRead: true, imageUrl: 'https://img.com/1.png');
      expect(updated.content, 'Modified');
      expect(updated.imageUrl, 'https://img.com/1.png');
      expect(updated.isRead, true);
      expect(updated.senderId, 'userA');
    });
  });

  group('ConversationModel & ConversationEntity Tests', () {
    test('ConversationModel converts to and from Map correctly for 1-1 chat', () {
      final conv = ConversationModel(
        id: 'user1_user2',
        participantIds: const ['user1', 'user2'],
        participantNames: const {
          'user1': 'Hà Mạnh Long',
          'user2': 'Nguyễn Văn An',
        },
        participantFaculties: const {
          'user1': 'CNTT',
          'user2': 'Dược - Y',
        },
        lastMessage: 'Ok bạn nha!',
        lastMessageSenderId: 'user1',
        lastMessageAt: DateTime(2026, 3, 1),
        unreadCounts: const {'user1': 0, 'user2': 1},
      );

      final map = conv.toMap();
      expect(map['participantIds'], ['user1', 'user2']);
      expect(map['lastMessage'], 'Ok bạn nha!');
      expect(map['isGroup'], false);

      final fromMap = ConversationModel.fromMap(map, 'user1_user2');
      expect(fromMap.id, 'user1_user2');
      expect(fromMap.isGroup, false);
      expect(fromMap.participantIds.length, 2);
      expect(fromMap.getDisplayName('user1'), 'Nguyễn Văn An');
      expect(fromMap.getOtherParticipantFaculty('user1'), 'Dược - Y');
      expect(fromMap.getUnreadCount('user2'), 1);
    });

    test('ConversationModel handles group chat correctly', () {
      final groupConv = ConversationModel(
        id: 'group_cntt',
        participantIds: const ['user1', 'user2', 'user3'],
        participantNames: const {
          'user1': 'Hà Mạnh Long',
          'user2': 'Nguyễn Văn An',
          'user3': 'Trần Thị Mai',
        },
        isGroup: true,
        groupName: 'Nhóm Đồ Án CNTT',
        adminId: 'user1',
        lastMessage: 'Hôm nay họp lúc 8h tối',
        lastMessageSenderId: 'user1',
        lastMessageAt: DateTime(2026, 3, 2),
      );

      final map = groupConv.toMap();
      expect(map['isGroup'], true);
      expect(map['groupName'], 'Nhóm Đồ Án CNTT');
      expect(map['adminId'], 'user1');

      final fromMap = ConversationModel.fromMap(map, 'group_cntt');
      expect(fromMap.isGroup, true);
      expect(fromMap.getDisplayName('user1'), 'Nhóm Đồ Án CNTT');
      expect(fromMap.getDisplayName('user2'), 'Nhóm Đồ Án CNTT');
      expect(fromMap.adminId, 'user1');
      expect(fromMap.participantIds.length, 3);
    });
  });

  group('ChatCubit Tests', () {
    late MockChatRepository mockRepo;
    late MockCloudinaryService mockCloudinary;
    late ChatCubit cubit;

    setUp(() {
      mockRepo = MockChatRepository();
      mockCloudinary = MockCloudinaryService();
      cubit = ChatCubit(
        chatRepository: mockRepo,
        cloudinaryService: mockCloudinary,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is ChatStatus.initial with empty lists', () {
      expect(cubit.state.status, ChatStatus.initial);
      expect(cubit.state.conversations, isEmpty);
      expect(cubit.state.currentMessages, isEmpty);
      expect(cubit.state.activeConversationId, isNull);
    });

    test('initConversations emits loaded state with conversations', () async {
      cubit.initConversations('userA');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, ChatStatus.loaded);
      expect(cubit.state.conversations.length, 1);
      expect(cubit.state.conversations.first.id, 'userA_userB');
    });

    test('openConversation sets activeId and loads messages', () async {
      cubit.openConversation('userA_userB', 'userA');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.activeConversationId, 'userA_userB');
      expect(cubit.state.currentMessages.length, 1);
      expect(cubit.state.currentMessages.first.content, 'Chào bạn, cho mình xin tài liệu nhé!');
    });

    test('sendMessage sends message through repository', () async {
      cubit.openConversation('userA_userB', 'userA');
      await Future.delayed(const Duration(milliseconds: 50));

      await cubit.sendMessage(
        conversationId: 'userA_userB',
        senderId: 'userA',
        senderName: 'Nguyễn Văn An',
        content: 'Tài liệu đây nhé bạn ơi!',
        participantIds: ['userA', 'userB'],
      );

      expect(cubit.state.isSending, false);
    });

    test('startDirectChat returns conversation id', () async {
      final convId = await cubit.startDirectChat(
        currentUserId: 'userX',
        currentUserName: 'User X',
        otherUserId: 'userY',
        otherUserName: 'User Y',
      );

      expect(convId, 'userX_userY');
      expect(cubit.state.activeConversationId, 'userX_userY');
    });

    test('createGroupConversation creates group and sets active conversation', () async {
      final convId = await cubit.createGroupConversation(
        groupName: 'Nhóm Ôn Thi Giải Tích',
        creatorId: 'userA',
        creatorName: 'Hà Mạnh Long',
        members: [
          {'id': 'userB', 'name': 'Trần Thị Mai', 'faculty': 'Dược - Y'},
          {'id': 'userC', 'name': 'Lê Hoàng Nam', 'faculty': 'Kinh tế'},
        ],
      );

      expect(convId, startsWith('group_'));
      expect(cubit.state.activeConversationId, convId);
    });

    test('leaveGroup leaves group and resets active conversation', () async {
      final convId = await cubit.createGroupConversation(
        groupName: 'Nhóm Tạm Thời',
        creatorId: 'userA',
        creatorName: 'User A',
        members: [
          {'id': 'userB', 'name': 'User B'},
        ],
      );

      expect(cubit.state.activeConversationId, convId);

      await cubit.leaveGroup(
        conversationId: convId,
        userId: 'userA',
      );

      expect(cubit.state.activeConversationId, isNull);
    });
  });
}
