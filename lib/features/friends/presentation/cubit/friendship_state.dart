import 'package:equatable/equatable.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/entities/relationship_entity.dart';

enum FriendshipActionStatus { initial, loading, success, failure }

class FriendshipState extends Equatable {
  final RelationshipEntity relationship;
  final List<FriendRequestEntity> receivedRequests;
  final List<Map<String, dynamic>> friendsList;
  final FriendshipActionStatus actionStatus;
  final String? message;

  const FriendshipState({
    this.relationship = const RelationshipEntity(),
    this.receivedRequests = const [],
    this.friendsList = const [],
    this.actionStatus = FriendshipActionStatus.initial,
    this.message,
  });

  FriendshipState copyWith({
    RelationshipEntity? relationship,
    List<FriendRequestEntity>? receivedRequests,
    List<Map<String, dynamic>>? friendsList,
    FriendshipActionStatus? actionStatus,
    String? message,
  }) {
    return FriendshipState(
      relationship: relationship ?? this.relationship,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      friendsList: friendsList ?? this.friendsList,
      actionStatus: actionStatus ?? this.actionStatus,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        relationship,
        receivedRequests,
        friendsList,
        actionStatus,
        message,
      ];
}
