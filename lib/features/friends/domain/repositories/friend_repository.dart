import '../entities/friend_request_entity.dart';
import '../entities/relationship_entity.dart';

abstract class FriendRepository {
  Stream<RelationshipEntity> getRelationshipStream({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> sendFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String targetUserId,
    required String targetUserName,
  });

  Future<void> cancelFriendRequest({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String senderFaculty,
  });

  Future<void> declineFriendRequest({
    required String currentUserId,
    required String senderId,
  });

  Future<void> unfriend({
    required String currentUserId,
    required String friendId,
  });

  Stream<List<FriendRequestEntity>> getReceivedFriendRequestsStream(String currentUserId);

  Stream<List<Map<String, dynamic>>> getFriendsStream(String userId);
}
