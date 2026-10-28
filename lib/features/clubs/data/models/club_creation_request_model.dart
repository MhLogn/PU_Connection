import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/club_creation_request_entity.dart';

class ClubCreationRequestModel extends ClubCreationRequestEntity {
  const ClubCreationRequestModel({
    required super.id,
    required super.clubName,
    required super.category,
    required super.description,
    required super.reason,
    required super.founderId,
    required super.founderName,
    required super.founderEmail,
    super.founderStudentId,
    super.founderFaculty,
    super.avatarUrl,
    super.coverUrl,
    super.schedule,
    super.location,
    super.benefits,
    super.contactEmail,
    super.contactPhone,
    super.status,
    super.adminFeedback,
    super.reviewedBy,
    super.reviewedByName,
    super.reviewedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory ClubCreationRequestModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ClubCreationRequestModel(
      id: id,
      clubName: map['clubName'] as String? ?? map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Học thuật',
      description:
          map['description'] as String? ?? map['desc'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      founderId: map['founderId'] as String? ?? map['leaderId'] as String? ?? '',
      founderName:
          map['founderName'] as String? ??
          map['leaderName'] as String? ??
          'Sinh viên Phenikaa',
      founderEmail: map['founderEmail'] as String? ?? '',
      founderStudentId: map['founderStudentId'] as String? ?? '',
      founderFaculty: map['founderFaculty'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? map['logoUrl'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      schedule:
          map['schedule'] as String? ??
          'Tối Thứ 4 & Chủ Nhật hàng tuần (18h30 - 20h30)',
      location:
          map['location'] as String? ??
          'Khu sinh hoạt CLB Tòa A9 & Sân trường Phenikaa',
      benefits:
          (map['benefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Cộng điểm rèn luyện (ĐRL) tiêu chí Hoạt động phong trào',
            'Cấp chứng nhận thành viên và cơ hội thi đấu cấp toàn quốc',
          ],
      contactEmail: map['contactEmail'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      adminFeedback: map['adminFeedback'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedByName: map['reviewedByName'] as String?,
      reviewedAt: parseDate(map['reviewedAt']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ClubCreationRequestModel.fromEntity(ClubCreationRequestEntity entity) {
    return ClubCreationRequestModel(
      id: entity.id,
      clubName: entity.clubName,
      category: entity.category,
      description: entity.description,
      reason: entity.reason,
      founderId: entity.founderId,
      founderName: entity.founderName,
      founderEmail: entity.founderEmail,
      founderStudentId: entity.founderStudentId,
      founderFaculty: entity.founderFaculty,
      avatarUrl: entity.avatarUrl,
      coverUrl: entity.coverUrl,
      schedule: entity.schedule,
      location: entity.location,
      benefits: entity.benefits,
      contactEmail: entity.contactEmail,
      contactPhone: entity.contactPhone,
      status: entity.status,
      adminFeedback: entity.adminFeedback,
      reviewedBy: entity.reviewedBy,
      reviewedByName: entity.reviewedByName,
      reviewedAt: entity.reviewedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ClubCreationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClubCreationRequestModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'clubName': clubName,
      'name': clubName,
      'category': category,
      'description': description,
      'desc': description,
      'reason': reason,
      'founderId': founderId,
      'leaderId': founderId,
      'founderName': founderName,
      'leaderName': founderName,
      'founderEmail': founderEmail,
      'founderStudentId': founderStudentId,
      'founderFaculty': founderFaculty,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'schedule': schedule,
      'location': location,
      'benefits': benefits,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'status': status,
      if (adminFeedback != null) 'adminFeedback': adminFeedback,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedByName != null) 'reviewedByName': reviewedByName,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
