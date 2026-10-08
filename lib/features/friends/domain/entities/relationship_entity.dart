import 'package:equatable/equatable.dart';
import 'friendship_status.dart';

class RelationshipEntity extends Equatable {
  final bool isFollowing;
  final FriendshipStatus friendshipStatus;
  final int followersCount;
  final int followingCount;
  final int friendsCount;

  const RelationshipEntity({
    this.isFollowing = false,
    this.friendshipStatus = FriendshipStatus.none,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
  });

  RelationshipEntity copyWith({
    bool? isFollowing,
    FriendshipStatus? friendshipStatus,
    int? followersCount,
    int? followingCount,
    int? friendsCount,
  }) {
    return RelationshipEntity(
      isFollowing: isFollowing ?? this.isFollowing,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      friendsCount: friendsCount ?? this.friendsCount,
    );
  }

  @override
  List<Object?> get props => [
        isFollowing,
        friendshipStatus,
        followersCount,
        followingCount,
        friendsCount,
      ];
}
