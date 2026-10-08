import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/entities/relationship_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import 'friendship_state.dart';

class FriendshipCubit extends BlocBase<FriendshipState> {
  final FriendRepository _friendRepository;

  StreamSubscription<RelationshipEntity>? _relationshipSub;
  StreamSubscription<List<FriendRequestEntity>>? _requestsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _friendsSub;

  FriendshipCubit({required FriendRepository friendRepository})
      : _friendRepository = friendRepository,
        super(const FriendshipState());

  void initRelationship({
    required String currentUserId,
    required String targetUserId,
  }) {
    _relationshipSub?.cancel();
    _friendsSub?.cancel();

    if (currentUserId.isEmpty || targetUserId.isEmpty) return;

    _relationshipSub = _friendRepository
        .getRelationshipStream(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        )
        .listen((relationship) {
      emit(state.copyWith(relationship: relationship));
    });

    _friendsSub = _friendRepository
        .getFriendsStream(targetUserId)
        .listen((friends) {
      emit(state.copyWith(friendsList: friends));
    });
  }

  void initReceivedRequests(String currentUserId) {
    _requestsSub?.cancel();
    if (currentUserId.isEmpty) return;

    _requestsSub = _friendRepository
        .getReceivedFriendRequestsStream(currentUserId)
        .listen((requests) {
      emit(state.copyWith(receivedRequests: requests));
    });
  }

  Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      if (state.relationship.isFollowing) {
        await _friendRepository.unfollowUser(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        );
        emit(state.copyWith(
          actionStatus: FriendshipActionStatus.success,
          message: 'Đã hủy theo dõi',
        ));
      } else {
        await _friendRepository.followUser(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        );
        emit(state.copyWith(
          actionStatus: FriendshipActionStatus.success,
          message: 'Đang theo dõi người dùng này',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Lỗi khi cập nhật theo dõi: $e',
      ));
    }
  }

  Future<void> sendFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String currentUserFaculty,
    required String targetUserId,
    required String targetUserName,
  }) async {
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      await _friendRepository.sendFriendRequest(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        currentUserFaculty: currentUserFaculty,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
      );
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.success,
        message: 'Đã gửi lời mời kết bạn!',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Không thể gửi lời mời kết bạn: $e',
      ));
    }
  }

  Future<void> cancelFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      await _friendRepository.cancelFriendRequest(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.success,
        message: 'Đã hủy lời mời kết bạn',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Lỗi khi hủy lời mời: $e',
      ));
    }
  }

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
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      await _friendRepository.acceptFriendRequest(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        currentUserFaculty: currentUserFaculty,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        senderFaculty: senderFaculty,
      );
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.success,
        message: 'Đã trở thành bạn bè với $senderName!',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Lỗi khi chấp nhận kết bạn: $e',
      ));
    }
  }

  Future<void> declineFriendRequest({
    required String currentUserId,
    required String senderId,
  }) async {
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      await _friendRepository.declineFriendRequest(
        currentUserId: currentUserId,
        senderId: senderId,
      );
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.success,
        message: 'Đã từ chối lời mời kết bạn',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Lỗi khi từ chối: $e',
      ));
    }
  }

  Future<void> unfriend({
    required String currentUserId,
    required String friendId,
  }) async {
    try {
      emit(state.copyWith(actionStatus: FriendshipActionStatus.loading));
      await _friendRepository.unfriend(
        currentUserId: currentUserId,
        friendId: friendId,
      );
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.success,
        message: 'Đã hủy kết bạn',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: FriendshipActionStatus.failure,
        message: 'Lỗi khi hủy kết bạn: $e',
      ));
    }
  }

  void clearMessage() {
    emit(state.copyWith(actionStatus: FriendshipActionStatus.initial, message: null));
  }

  @override
  Future<void> close() {
    _relationshipSub?.cancel();
    _requestsSub?.cancel();
    _friendsSub?.cancel();
    return super.close();
  }
}
