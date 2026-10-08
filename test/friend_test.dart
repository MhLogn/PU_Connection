import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/friends/domain/entities/friendship_status.dart';
import 'package:pu_connection/features/friends/domain/entities/relationship_entity.dart';
import 'package:pu_connection/features/friends/data/models/friend_request_model.dart';
import 'package:pu_connection/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:pu_connection/features/friends/presentation/cubit/friendship_cubit.dart';
import 'package:pu_connection/features/friends/presentation/cubit/friendship_state.dart';

void main() {
  setUp(() {
    FriendRepositoryImpl.resetMemory();
  });

  group('Entities and Models Tests', () {
    test('RelationshipEntity properties and copyWith', () {
      const rel = RelationshipEntity(
        isFollowing: true,
        friendshipStatus: FriendshipStatus.friends,
        followersCount: 15,
        followingCount: 10,
        friendsCount: 5,
      );

      expect(rel.isFollowing, isTrue);
      expect(rel.friendshipStatus, FriendshipStatus.friends);
      expect(rel.followersCount, 15);
      expect(rel.followingCount, 10);
      expect(rel.friendsCount, 5);

      final updated = rel.copyWith(isFollowing: false, friendsCount: 6);
      expect(updated.isFollowing, isFalse);
      expect(updated.friendsCount, 6);
      expect(updated.followersCount, 15);
    });

    test('FriendRequestModel serialization to and from Map', () {
      final now = DateTime.now();
      final model = FriendRequestModel(
        id: 'req_123',
        senderId: 'user_a',
        senderName: 'Nguyễn Văn A',
        senderAvatar: 'https://example.com/a.jpg',
        senderFaculty: 'Khoa CNTT',
        receiverId: 'user_b',
        receiverName: 'Trần Thị B',
        createdAt: now,
        status: 'pending',
      );

      final map = model.toMap();
      expect(map['senderId'], 'user_a');
      expect(map['receiverId'], 'user_b');
      expect(map['status'], 'pending');

      final deserialized = FriendRequestModel.fromMap(map, 'req_123');
      expect(deserialized.id, 'req_123');
      expect(deserialized.senderName, 'Nguyễn Văn A');
      expect(deserialized.status, 'pending');
    });
  });

  group('FriendRepositoryImpl Tests', () {
    late FriendRepositoryImpl repository;

    setUp(() {
      FriendRepositoryImpl.resetMemory();
      repository = FriendRepositoryImpl();
    });

    test('followUser and unfollowUser update streams properly', () async {
      final stream = repository.getRelationshipStream(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      );

      expectLater(
        stream,
        emitsInOrder([
          predicate<RelationshipEntity>((r) => !r.isFollowing && r.followersCount == 0),
          predicate<RelationshipEntity>((r) => r.isFollowing && r.followersCount == 1),
          predicate<RelationshipEntity>((r) => !r.isFollowing && r.followersCount == 0),
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await repository.followUser(currentUserId: 'user_1', targetUserId: 'user_2');

      await Future.delayed(const Duration(milliseconds: 50));
      await repository.unfollowUser(currentUserId: 'user_1', targetUserId: 'user_2');
    });

    test('sendFriendRequest and cancelFriendRequest update relationship and requests stream', () async {
      await repository.sendFriendRequest(
        currentUserId: 'user_1',
        currentUserName: 'User One',
        currentUserAvatar: '',
        currentUserFaculty: 'CNTT',
        targetUserId: 'user_2',
        targetUserName: 'User Two',
      );

      final relStream = repository.getRelationshipStream(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      );
      final rel = await relStream.first;
      expect(rel.friendshipStatus, FriendshipStatus.requestSent);

      final recvStream = repository.getReceivedFriendRequestsStream('user_2');
      final requests = await recvStream.first;
      expect(requests.length, 1);
      expect(requests.first.senderId, 'user_1');

      await repository.cancelFriendRequest(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      );

      final relAfterCancel = await repository.getRelationshipStream(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      ).first;
      expect(relAfterCancel.friendshipStatus, FriendshipStatus.none);
    });

    test('acceptFriendRequest establishes friendship and updates friends stream', () async {
      await repository.sendFriendRequest(
        currentUserId: 'user_1',
        currentUserName: 'User One',
        currentUserAvatar: '',
        currentUserFaculty: 'CNTT',
        targetUserId: 'user_2',
        targetUserName: 'User Two',
      );

      await repository.acceptFriendRequest(
        currentUserId: 'user_2',
        currentUserName: 'User Two',
        currentUserAvatar: '',
        currentUserFaculty: 'Kinh tế',
        senderId: 'user_1',
        senderName: 'User One',
        senderAvatar: '',
        senderFaculty: 'CNTT',
      );

      final rel1 = await repository.getRelationshipStream(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      ).first;
      expect(rel1.friendshipStatus, FriendshipStatus.friends);

      final rel2 = await repository.getRelationshipStream(
        currentUserId: 'user_2',
        targetUserId: 'user_1',
      ).first;
      expect(rel2.friendshipStatus, FriendshipStatus.friends);

      final friendsOfUser2 = await repository.getFriendsStream('user_2').first;
      expect(friendsOfUser2.length, 1);
      expect(friendsOfUser2.first['userId'], 'user_1');

      await repository.unfriend(currentUserId: 'user_1', friendId: 'user_2');
      final relAfterUnfriend = await repository.getRelationshipStream(
        currentUserId: 'user_1',
        targetUserId: 'user_2',
      ).first;
      expect(relAfterUnfriend.friendshipStatus, FriendshipStatus.none);
    });
  });

  group('FriendshipCubit Tests', () {
    late FriendRepositoryImpl repository;
    late FriendshipCubit cubit;

    setUp(() {
      FriendRepositoryImpl.resetMemory();
      repository = FriendRepositoryImpl();
      cubit = FriendshipCubit(friendRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is empty', () {
      expect(cubit.state.relationship.isFollowing, isFalse);
      expect(cubit.state.relationship.friendshipStatus, FriendshipStatus.none);
      expect(cubit.state.actionStatus, FriendshipActionStatus.initial);
    });

    test('toggleFollow toggles following state and emits success message', () async {
      cubit.initRelationship(currentUserId: 'user_1', targetUserId: 'user_2');
      await Future.delayed(const Duration(milliseconds: 50));

      await cubit.toggleFollow(currentUserId: 'user_1', targetUserId: 'user_2');
      expect(cubit.state.actionStatus, FriendshipActionStatus.success);
      expect(cubit.state.message, contains('theo dõi'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.relationship.isFollowing, isTrue);

      await cubit.toggleFollow(currentUserId: 'user_1', targetUserId: 'user_2');
      expect(cubit.state.actionStatus, FriendshipActionStatus.success);
      expect(cubit.state.message, contains('hủy theo dõi'));
    });

    test('sendFriendRequest and cancelFriendRequest flow in Cubit', () async {
      cubit.initRelationship(currentUserId: 'user_1', targetUserId: 'user_2');
      await Future.delayed(const Duration(milliseconds: 50));

      await cubit.sendFriendRequest(
        currentUserId: 'user_1',
        currentUserName: 'User One',
        currentUserAvatar: '',
        currentUserFaculty: 'CNTT',
        targetUserId: 'user_2',
        targetUserName: 'User Two',
      );

      expect(cubit.state.actionStatus, FriendshipActionStatus.success);
      expect(cubit.state.message, contains('lời mời kết bạn'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.relationship.friendshipStatus, FriendshipStatus.requestSent);

      await cubit.cancelFriendRequest(currentUserId: 'user_1', targetUserId: 'user_2');
      expect(cubit.state.actionStatus, FriendshipActionStatus.success);
      expect(cubit.state.message, contains('hủy lời mời'));
    });
  });
}
