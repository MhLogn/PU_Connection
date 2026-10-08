import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/entities/friendship_status.dart';
import '../../domain/entities/relationship_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../models/friend_request_model.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FirebaseFirestore? _customFirestore;

  FriendRepositoryImpl({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  // --- In-memory mock storage for tests and offline mode ---
  static final Map<String, Set<String>> _memoryFollowing = {}; // userId -> Set<targetUserId>
  static final Map<String, Set<String>> _memoryFollowers = {}; // userId -> Set<followerUserId>
  static final Map<String, Set<String>> _memoryFriends = {}; // userId -> Set<friendUserId>
  static final Map<String, Map<String, dynamic>> _memoryUsersInfo = {}; // userId -> user info map
  static final List<FriendRequestEntity> _memoryRequests = []; // All pending/active requests

  static final StreamController<void> _changeNotifier = StreamController<void>.broadcast();

  static void resetMemory() {
    _memoryFollowing.clear();
    _memoryFollowers.clear();
    _memoryFriends.clear();
    _memoryUsersInfo.clear();
    _memoryRequests.clear();
  }

  @override
  Stream<RelationshipEntity> getRelationshipStream({
    required String currentUserId,
    required String targetUserId,
  }) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emitCurrent() {
          final isFollowing = _memoryFollowing[currentUserId]?.contains(targetUserId) ?? false;
          final isFriend = _memoryFriends[currentUserId]?.contains(targetUserId) ?? false;

          FriendshipStatus status = FriendshipStatus.none;
          if (isFriend) {
            status = FriendshipStatus.friends;
          } else {
            final sentReq = _memoryRequests.any((r) =>
                r.senderId == currentUserId &&
                r.receiverId == targetUserId &&
                r.status == 'pending');
            if (sentReq) {
              status = FriendshipStatus.requestSent;
            } else {
              final recvReq = _memoryRequests.any((r) =>
                  r.senderId == targetUserId &&
                  r.receiverId == currentUserId &&
                  r.status == 'pending');
              if (recvReq) {
                status = FriendshipStatus.requestReceived;
              }
            }
          }

          final followersCount = _memoryFollowers[targetUserId]?.length ?? 0;
          final followingCount = _memoryFollowing[targetUserId]?.length ?? 0;
          final friendsCount = _memoryFriends[targetUserId]?.length ?? 0;

          controller.add(RelationshipEntity(
            isFollowing: isFollowing,
            friendshipStatus: status,
            followersCount: followersCount,
            followingCount: followingCount,
            friendsCount: friendsCount,
          ));
        }

        emitCurrent();
        final sub = _changeNotifier.stream.listen((_) => emitCurrent());
        controller.onCancel = () => sub.cancel();
      });
    }

    // Firestore implementation
    return Stream.multi((controller) {
      RelationshipEntity latest = const RelationshipEntity();

      void updateAndEmit({
        bool? isFollowing,
        FriendshipStatus? friendshipStatus,
        int? followersCount,
        int? followingCount,
        int? friendsCount,
      }) {
        latest = latest.copyWith(
          isFollowing: isFollowing,
          friendshipStatus: friendshipStatus,
          followersCount: followersCount,
          followingCount: followingCount,
          friendsCount: friendsCount,
        );
        controller.add(latest);
      }

      // 1. Follow check
      final followSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .collection(FirebaseConstants.followingSubcollection)
          .doc(targetUserId)
          .snapshots()
          .listen((doc) {
        updateAndEmit(isFollowing: doc.exists);
      });

      // 2. Friends check
      final friendSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .collection(FirebaseConstants.friendsSubcollection)
          .doc(targetUserId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          updateAndEmit(friendshipStatus: FriendshipStatus.friends);
        }
      });

      // 3. Sent request check
      final sentReqSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .collection(FirebaseConstants.friendRequestsSubcollection)
          .doc('sent_$targetUserId')
          .snapshots()
          .listen((doc) {
        if (doc.exists && latest.friendshipStatus != FriendshipStatus.friends) {
          updateAndEmit(friendshipStatus: FriendshipStatus.requestSent);
        } else if (!doc.exists && latest.friendshipStatus == FriendshipStatus.requestSent) {
          updateAndEmit(friendshipStatus: FriendshipStatus.none);
        }
      });

      // 4. Received request check
      final recvReqSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .collection(FirebaseConstants.friendRequestsSubcollection)
          .doc('recv_$targetUserId')
          .snapshots()
          .listen((doc) {
        if (doc.exists && latest.friendshipStatus != FriendshipStatus.friends) {
          updateAndEmit(friendshipStatus: FriendshipStatus.requestReceived);
        } else if (!doc.exists && latest.friendshipStatus == FriendshipStatus.requestReceived) {
          updateAndEmit(friendshipStatus: FriendshipStatus.none);
        }
      });

      // 5. Counters from target user's collections
      final targetFollowersSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(targetUserId)
          .collection(FirebaseConstants.followersSubcollection)
          .snapshots()
          .listen((snap) {
        updateAndEmit(followersCount: snap.docs.length);
      });

      final targetFollowingSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(targetUserId)
          .collection(FirebaseConstants.followingSubcollection)
          .snapshots()
          .listen((snap) {
        updateAndEmit(followingCount: snap.docs.length);
      });

      final targetFriendsSub = firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(targetUserId)
          .collection(FirebaseConstants.friendsSubcollection)
          .snapshots()
          .listen((snap) {
        updateAndEmit(friendsCount: snap.docs.length);
      });

      controller.onCancel = () {
        followSub.cancel();
        friendSub.cancel();
        sentReqSub.cancel();
        recvReqSub.cancel();
        targetFollowersSub.cancel();
        targetFollowingSub.cancel();
        targetFriendsSub.cancel();
      };
    });
  }

  @override
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty || currentUserId == targetUserId) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();
        final myFollowingRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.followingSubcollection)
            .doc(targetUserId);

        final targetFollowerRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(targetUserId)
            .collection(FirebaseConstants.followersSubcollection)
            .doc(currentUserId);

        batch.set(myFollowingRef, {
          'userId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(targetFollowerRef, {
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        return;
      } catch (_) {}
    }

    // In-memory fallback
    _memoryFollowing.putIfAbsent(currentUserId, () => {}).add(targetUserId);
    _memoryFollowers.putIfAbsent(targetUserId, () => {}).add(currentUserId);
    _changeNotifier.add(null);
  }

  @override
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();
        final myFollowingRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.followingSubcollection)
            .doc(targetUserId);

        final targetFollowerRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(targetUserId)
            .collection(FirebaseConstants.followersSubcollection)
            .doc(currentUserId);

        batch.delete(myFollowingRef);
        batch.delete(targetFollowerRef);

        await batch.commit();
        return;
      } catch (_) {}
    }

    _memoryFollowing[currentUserId]?.remove(targetUserId);
    _memoryFollowers[targetUserId]?.remove(currentUserId);
    _changeNotifier.add(null);
  }

  @override
  Future<void> sendFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String targetUserId,
    required String targetUserName,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty || currentUserId == targetUserId) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();

        // Save sender's sent marker
        final sentRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('sent_$targetUserId');

        batch.set(sentRef, {
          'targetUserId': targetUserId,
          'targetUserName': targetUserName,
          'type': 'sent',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save receiver's pending request
        final recvRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(targetUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('recv_$currentUserId');

        batch.set(recvRef, {
          'senderId': currentUserId,
          'senderName': currentUserName,
          'senderAvatar': currentUserAvatar,
          'senderFaculty': currentUserFaculty,
          'receiverId': targetUserId,
          'receiverName': targetUserName,
          'type': 'received',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        return;
      } catch (_) {}
    }

    // In-memory fallback
    _memoryRequests.removeWhere(
        (r) => r.senderId == currentUserId && r.receiverId == targetUserId);
    _memoryRequests.add(FriendRequestEntity(
      id: 'req_${currentUserId}_$targetUserId',
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      senderFaculty: currentUserFaculty,
      receiverId: targetUserId,
      receiverName: targetUserName,
      createdAt: DateTime.now(),
      status: 'pending',
    ));
    _changeNotifier.add(null);
  }

  @override
  Future<void> cancelFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();
        final sentRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('sent_$targetUserId');

        final recvRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(targetUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('recv_$currentUserId');

        batch.delete(sentRef);
        batch.delete(recvRef);

        await batch.commit();
        return;
      } catch (_) {}
    }

    _memoryRequests.removeWhere(
        (r) => r.senderId == currentUserId && r.receiverId == targetUserId);
    _changeNotifier.add(null);
  }

  @override
  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String senderFaculty,
  }) async {
    if (currentUserId.isEmpty || senderId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();

        // 1. Delete the requests
        final recvRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('recv_$senderId');

        final sentRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(senderId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('sent_$currentUserId');

        batch.delete(recvRef);
        batch.delete(sentRef);

        // 2. Add two-way friend relationship
        final myFriendRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendsSubcollection)
            .doc(senderId);

        final senderFriendRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(senderId)
            .collection(FirebaseConstants.friendsSubcollection)
            .doc(currentUserId);

        batch.set(myFriendRef, {
          'userId': senderId,
          'displayName': senderName,
          'avatarUrl': senderAvatar,
          'faculty': senderFaculty,
          'connectedAt': FieldValue.serverTimestamp(),
        });

        batch.set(senderFriendRef, {
          'userId': currentUserId,
          'displayName': currentUserName,
          'avatarUrl': currentUserAvatar,
          'faculty': currentUserFaculty,
          'connectedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        return;
      } catch (_) {}
    }

    // In-memory fallback
    _memoryRequests.removeWhere((r) =>
        (r.senderId == senderId && r.receiverId == currentUserId) ||
        (r.senderId == currentUserId && r.receiverId == senderId));

    _memoryFriends.putIfAbsent(currentUserId, () => {}).add(senderId);
    _memoryFriends.putIfAbsent(senderId, () => {}).add(currentUserId);

    _memoryUsersInfo[senderId] = {
      'userId': senderId,
      'displayName': senderName,
      'avatarUrl': senderAvatar,
      'faculty': senderFaculty,
    };
    _memoryUsersInfo[currentUserId] = {
      'userId': currentUserId,
      'displayName': currentUserName,
      'avatarUrl': currentUserAvatar,
      'faculty': currentUserFaculty,
    };

    _changeNotifier.add(null);
  }

  @override
  Future<void> declineFriendRequest({
    required String currentUserId,
    required String senderId,
  }) async {
    if (currentUserId.isEmpty || senderId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();
        final recvRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('recv_$senderId');

        final sentRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(senderId)
            .collection(FirebaseConstants.friendRequestsSubcollection)
            .doc('sent_$currentUserId');

        batch.delete(recvRef);
        batch.delete(sentRef);

        await batch.commit();
        return;
      } catch (_) {}
    }

    _memoryRequests.removeWhere(
        (r) => r.senderId == senderId && r.receiverId == currentUserId);
    _changeNotifier.add(null);
  }

  @override
  Future<void> unfriend({
    required String currentUserId,
    required String friendId,
  }) async {
    if (currentUserId.isEmpty || friendId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final batch = firestore.batch();
        final myFriendRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.friendsSubcollection)
            .doc(friendId);

        final otherFriendRef = firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(friendId)
            .collection(FirebaseConstants.friendsSubcollection)
            .doc(currentUserId);

        batch.delete(myFriendRef);
        batch.delete(otherFriendRef);

        await batch.commit();
        return;
      } catch (_) {}
    }

    _memoryFriends[currentUserId]?.remove(friendId);
    _memoryFriends[friendId]?.remove(currentUserId);
    _changeNotifier.add(null);
  }

  @override
  Stream<List<FriendRequestEntity>> getReceivedFriendRequestsStream(String currentUserId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emitRequests() {
          final list = _memoryRequests
              .where((r) => r.receiverId == currentUserId && r.status == 'pending')
              .toList();
          controller.add(list);
        }

        emitRequests();
        final sub = _changeNotifier.stream.listen((_) => emitRequests());
        controller.onCancel = () => sub.cancel();
      });
    }

    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(currentUserId)
        .collection(FirebaseConstants.friendRequestsSubcollection)
        .where('type', isEqualTo: 'received')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FriendRequestModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getFriendsStream(String userId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emitFriends() {
          final friendIds = _memoryFriends[userId] ?? {};
          final list = friendIds.map((fId) {
            final info = _memoryUsersInfo[fId];
            return {
              'userId': fId,
              'displayName': info?['displayName'] ?? 'Sinh viên PU',
              'avatarUrl': info?['avatarUrl'] ?? '',
              'faculty': info?['faculty'] ?? 'Khoa CNTT',
            };
          }).toList();
          controller.add(list);
        }

        emitFriends();
        final sub = _changeNotifier.stream.listen((_) => emitFriends());
        controller.onCancel = () => sub.cancel();
      });
    }

    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.friendsSubcollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Sinh viên Phenikaa',
          'avatarUrl': data['avatarUrl'] ?? '',
          'faculty': data['faculty'] ?? '',
        };
      }).toList();
    });
  }
}
