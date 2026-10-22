import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/study_group_entity.dart';

class StudyGroupModel extends StudyGroupEntity {
  const StudyGroupModel({
    required super.id,
    required super.creatorId,
    required super.creatorName,
    super.creatorAvatar,
    super.creatorStudentId = '',
    super.creatorFaculty = '',
    required super.title,
    required super.subject,
    required super.description,
    super.maxMembers = 5,
    super.memberIds = const [],
    super.pendingRequestIds = const [],
    required super.studyTime,
    required super.location,
    required super.createdAt,
    super.isOpen = true,
  });

  factory StudyGroupModel.fromEntity(StudyGroupEntity entity) {
    return StudyGroupModel(
      id: entity.id,
      creatorId: entity.creatorId,
      creatorName: entity.creatorName,
      creatorAvatar: entity.creatorAvatar,
      creatorStudentId: entity.creatorStudentId,
      creatorFaculty: entity.creatorFaculty,
      title: entity.title,
      subject: entity.subject,
      description: entity.description,
      maxMembers: entity.maxMembers,
      memberIds: entity.memberIds,
      pendingRequestIds: entity.pendingRequestIds,
      studyTime: entity.studyTime,
      location: entity.location,
      createdAt: entity.createdAt,
      isOpen: entity.isOpen,
    );
  }

  factory StudyGroupModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return StudyGroupModel(
      id: id,
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'Sinh viên Phenikaa',
      creatorAvatar: map['creatorAvatar'] as String?,
      creatorStudentId: map['creatorStudentId'] as String? ?? '',
      creatorFaculty: map['creatorFaculty'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? 'Chung',
      description: map['description'] as String? ?? '',
      maxMembers: (map['maxMembers'] as num?)?.toInt() ?? 5,
      memberIds: (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pendingRequestIds: (map['pendingRequestIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      studyTime: parseDate(map['studyTime']),
      location: map['location'] as String? ?? 'Thư viện Phenikaa',
      createdAt: parseDate(map['createdAt']),
      isOpen: map['isOpen'] as bool? ?? true,
    );
  }

  factory StudyGroupModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudyGroupModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorAvatar': creatorAvatar,
      'creatorStudentId': creatorStudentId,
      'creatorFaculty': creatorFaculty,
      'title': title,
      'subject': subject,
      'description': description,
      'maxMembers': maxMembers,
      'memberIds': memberIds,
      'pendingRequestIds': pendingRequestIds,
      'studyTime': Timestamp.fromDate(studyTime),
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOpen': isOpen,
    };
  }
}
