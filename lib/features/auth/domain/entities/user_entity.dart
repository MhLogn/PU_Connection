import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String studentId;
  final String displayName;
  final String username;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String faculty;
  final String major;
  final int cohort;
  final String userType; // 'student' | 'lecturer' | 'staff' | 'admin'
  final bool isVerified;
  final List<String> currentSubjects;
  final int friendsCount;
  final int postsCount;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    this.studentId = '',
    this.displayName = '',
    this.username = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.bio = '',
    this.faculty = '',
    this.major = '',
    this.cohort = 0,
    this.userType = 'student',
    this.isVerified = false,
    this.currentSubjects = const [],
    this.friendsCount = 0,
    this.postsCount = 0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        studentId,
        displayName,
        username,
        avatarUrl,
        coverUrl,
        bio,
        faculty,
        major,
        cohort,
        userType,
        isVerified,
        currentSubjects,
        friendsCount,
        postsCount,
        createdAt,
      ];
}
