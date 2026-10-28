import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.studentId,
    super.displayName,
    super.username,
    super.avatarUrl,
    super.coverUrl,
    super.bio,
    super.faculty,
    super.major,
    super.cohort,
    super.userType,
    super.isVerified,
    super.isBanned,
    super.currentSubjects,
    super.friendsCount,
    super.postsCount,
    super.createdAt,
    super.gpa,
    super.creditsEarned,
    super.trainingPoints,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      faculty: map['faculty'] as String? ?? '',
      major: map['major'] as String? ?? '',
      cohort: (map['cohort'] as num?)?.toInt() ?? 0,
      userType: map['userType'] as String? ?? 'student',
      isVerified: map['isVerified'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      currentSubjects: List<String>.from(map['currentSubjects'] as List? ?? []),
      friendsCount: (map['friendsCount'] as num?)?.toInt() ?? 0,
      postsCount: (map['postsCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      gpa: (map['gpa'] as num?)?.toDouble() ?? 0.0,
      creditsEarned: (map['creditsEarned'] as num?)?.toInt() ?? 0,
      trainingPoints: (map['trainingPoints'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'studentId': studentId,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'faculty': faculty,
      'major': major,
      'cohort': cohort,
      'userType': userType,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'currentSubjects': currentSubjects,
      'friendsCount': friendsCount,
      'postsCount': postsCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'gpa': gpa,
      'creditsEarned': creditsEarned,
      'trainingPoints': trainingPoints,
    };
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
}
