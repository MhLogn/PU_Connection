import 'package:equatable/equatable.dart';
import '../../domain/entities/blocked_user_entity.dart';

enum ModerationActionStatus { initial, loading, success, failure }

class ModerationState extends Equatable {
  final List<BlockedUserEntity> blockedUsers;
  final Set<String> blockedUserIds;
  final Set<String> hiddenPostIds; // Local optimistic hiding for reported/blocked posts
  final ModerationActionStatus status;
  final String? message;

  const ModerationState({
    this.blockedUsers = const [],
    this.blockedUserIds = const {},
    this.hiddenPostIds = const {},
    this.status = ModerationActionStatus.initial,
    this.message,
  });

  ModerationState copyWith({
    List<BlockedUserEntity>? blockedUsers,
    Set<String>? blockedUserIds,
    Set<String>? hiddenPostIds,
    ModerationActionStatus? status,
    String? message,
  }) {
    return ModerationState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        blockedUsers,
        blockedUserIds,
        hiddenPostIds,
        status,
        message,
      ];
}
