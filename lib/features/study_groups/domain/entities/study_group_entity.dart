import 'package:equatable/equatable.dart';

class StudyGroupEntity extends Equatable {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;
  final String creatorStudentId;
  final String creatorFaculty;
  final String title;
  final String subject;
  final String description;
  final int maxMembers;
  final List<String> memberIds;
  final List<String> pendingRequestIds;
  final DateTime studyTime;
  final String location;
  final DateTime createdAt;
  final bool isOpen;

  const StudyGroupEntity({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar,
    this.creatorStudentId = '',
    this.creatorFaculty = '',
    required this.title,
    required this.subject,
    required this.description,
    this.maxMembers = 5,
    this.memberIds = const [],
    this.pendingRequestIds = const [],
    required this.studyTime,
    required this.location,
    required this.createdAt,
    this.isOpen = true,
  });

  int get currentMembersCount => memberIds.length;
  bool get isFull => memberIds.length >= maxMembers;
  bool isMember(String uid) => memberIds.contains(uid);
  bool isCreator(String uid) => creatorId == uid;
  bool hasRequested(String uid) => pendingRequestIds.contains(uid);

  StudyGroupEntity copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    String? creatorStudentId,
    String? creatorFaculty,
    String? title,
    String? subject,
    String? description,
    int? maxMembers,
    List<String>? memberIds,
    List<String>? pendingRequestIds,
    DateTime? studyTime,
    String? location,
    DateTime? createdAt,
    bool? isOpen,
  }) {
    return StudyGroupEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      creatorStudentId: creatorStudentId ?? this.creatorStudentId,
      creatorFaculty: creatorFaculty ?? this.creatorFaculty,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      maxMembers: maxMembers ?? this.maxMembers,
      memberIds: memberIds ?? this.memberIds,
      pendingRequestIds: pendingRequestIds ?? this.pendingRequestIds,
      studyTime: studyTime ?? this.studyTime,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  List<Object?> get props => [
    id,
    creatorId,
    creatorName,
    creatorAvatar,
    creatorStudentId,
    creatorFaculty,
    title,
    subject,
    description,
    maxMembers,
    memberIds,
    pendingRequestIds,
    studyTime,
    location,
    createdAt,
    isOpen,
  ];
}
