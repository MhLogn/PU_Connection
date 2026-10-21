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
  final bool isBanned;
  final List<String> currentSubjects;
  final int friendsCount;
  final int postsCount;
  final DateTime? createdAt;
  final double gpa;
  final int creditsEarned;
  final int trainingPoints;

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
    this.isBanned = false,
    this.currentSubjects = const [],
    this.friendsCount = 0,
    this.postsCount = 0,
    this.createdAt,
    this.gpa = 0.0,
    this.creditsEarned = 0,
    this.trainingPoints = 0,
  });

  bool get isAdmin => userType.toLowerCase() == 'admin' || email.toLowerCase().startsWith('admin');

  UserEntity copyWith({
    String? uid,
    String? email,
    String? studentId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? faculty,
    String? major,
    int? cohort,
    String? userType,
    bool? isVerified,
    bool? isBanned,
    List<String>? currentSubjects,
    int? friendsCount,
    int? postsCount,
    DateTime? createdAt,
    double? gpa,
    int? creditsEarned,
    int? trainingPoints,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      currentSubjects: currentSubjects ?? this.currentSubjects,
      friendsCount: friendsCount ?? this.friendsCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt ?? this.createdAt,
      gpa: gpa ?? this.gpa,
      creditsEarned: creditsEarned ?? this.creditsEarned,
      trainingPoints: trainingPoints ?? this.trainingPoints,
    );
  }

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
        isBanned,
        currentSubjects,
        friendsCount,
        postsCount,
        createdAt,
        gpa,
        creditsEarned,
        trainingPoints,
      ];
}
