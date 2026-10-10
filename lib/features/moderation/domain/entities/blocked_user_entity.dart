import 'package:equatable/equatable.dart';

class BlockedUserEntity extends Equatable {
  final String userId;
  final String userName;
  final String userAvatar;
  final String userFaculty;
  final DateTime? blockedAt;

  const BlockedUserEntity({
    required this.userId,
    this.userName = '',
    this.userAvatar = '',
    this.userFaculty = '',
    this.blockedAt,
  });

  BlockedUserEntity copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    String? userFaculty,
    DateTime? blockedAt,
  }) {
    return BlockedUserEntity(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userFaculty: userFaculty ?? this.userFaculty,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        userName,
        userAvatar,
        userFaculty,
        blockedAt,
      ];
}
