import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ConversationEntity>> getConversationsStream(String currentUserId) {
    return _firestore
        .collection(FirebaseConstants.chatsCollection)
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final timeA = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
      return list;
    });
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(FirebaseConstants.chatsCollection)
        .doc(conversationId)
        .collection(FirebaseConstants.messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required MessageEntity message,
    required List<String> participantIds,
  }) async {
    final convRef = _firestore
        .collection(FirebaseConstants.chatsCollection)
        .doc(conversationId);

    final msgRef = convRef
        .collection(FirebaseConstants.messagesSubcollection)
        .doc(message.messageId.isNotEmpty ? message.messageId : null);

    final msgModel = MessageModel(
      messageId: msgRef.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      imageUrl: message.imageUrl,
      createdAt: message.createdAt,
      isRead: false,
    );

    final otherParticipants =
        participantIds.where((id) => id != message.senderId).toList();

    final Map<String, dynamic> updateData = {
      'lastMessage': message.content.isNotEmpty
          ? message.content
          : (message.imageUrl != null ? '[Hình ảnh]' : ''),
      'lastMessageSenderId': message.senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };

    for (final otherId in otherParticipants) {
      updateData['unreadCounts.$otherId'] = FieldValue.increment(1);
    }

    final batch = _firestore.batch();
    batch.set(msgRef, msgModel.toMap());
    batch.set(convRef, updateData, SetOptions(merge: true));

    await batch.commit();
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
    final sortedIds = [currentUserId, otherUserId]..sort();
    final convId = '${sortedIds[0]}_${sortedIds[1]}';

    final convDoc = _firestore
        .collection(FirebaseConstants.chatsCollection)
        .doc(convId);

    final snap = await convDoc.get();
    if (!snap.exists) {
      await convDoc.set({
        'participantIds': sortedIds,
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'participantAvatars': {
          currentUserId: currentUserAvatar,
          otherUserId: otherUserAvatar,
        },
        'participantFaculties': {
          currentUserId: currentUserFaculty,
          otherUserId: otherUserFaculty,
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
      });
    } else {
      await convDoc.set({
        'participantNames.$currentUserId': currentUserName,
        'participantNames.$otherUserId': otherUserName,
        'participantAvatars.$currentUserId': currentUserAvatar,
        'participantAvatars.$otherUserId': otherUserAvatar,
        'participantFaculties.$currentUserId': currentUserFaculty,
        'participantFaculties.$otherUserId': otherUserFaculty,
      }, SetOptions(merge: true));
    }

    return convId;
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final convDoc = _firestore
        .collection(FirebaseConstants.chatsCollection)
        .doc(conversationId);

    await convDoc.set({
      'unreadCounts.$currentUserId': 0,
    }, SetOptions(merge: true));
  }
}
