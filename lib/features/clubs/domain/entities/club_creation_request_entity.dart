import 'package:equatable/equatable.dart';

class ClubCreationRequestEntity extends Equatable {
  final String id;
  final String clubName;
  final String category;
  final String description;
  final String reason;
  final String founderId;
  final String founderName;
  final String founderEmail;
  final String founderStudentId;
  final String founderFaculty;
  final String avatarUrl;
  final String coverUrl;
  final String schedule;
  final String location;
  final List<String> benefits;
  final String contactEmail;
  final String contactPhone;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminFeedback;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClubCreationRequestEntity({
    required this.id,
    required this.clubName,
    required this.category,
    required this.description,
    required this.reason,
    required this.founderId,
    required this.founderName,
    required this.founderEmail,
    this.founderStudentId = '',
    this.founderFaculty = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.schedule = 'Tối Thứ 4 & Chủ Nhật hàng tuần (18h30 - 20h30)',
    this.location = 'Khu sinh hoạt CLB Tòa A9 & Sân trường Phenikaa',
    this.benefits = const [
      'Cộng điểm rèn luyện (ĐRL) tiêu chí Hoạt động phong trào',
      'Cấp chứng nhận thành viên và cơ hội thi đấu cấp toàn quốc',
    ],
    this.contactEmail = '',
    this.contactPhone = '',
    this.status = 'pending',
    this.adminFeedback,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  ClubCreationRequestEntity copyWith({
    String? id,
    String? clubName,
    String? category,
    String? description,
    String? reason,
    String? founderId,
    String? founderName,
    String? founderEmail,
    String? founderStudentId,
    String? founderFaculty,
    String? avatarUrl,
    String? coverUrl,
    String? schedule,
    String? location,
    List<String>? benefits,
    String? contactEmail,
    String? contactPhone,
    String? status,
    String? adminFeedback,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClubCreationRequestEntity(
      id: id ?? this.id,
      clubName: clubName ?? this.clubName,
      category: category ?? this.category,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      founderId: founderId ?? this.founderId,
      founderName: founderName ?? this.founderName,
      founderEmail: founderEmail ?? this.founderEmail,
      founderStudentId: founderStudentId ?? this.founderStudentId,
      founderFaculty: founderFaculty ?? this.founderFaculty,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      benefits: benefits ?? this.benefits,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clubName,
    category,
    description,
    reason,
    founderId,
    founderName,
    founderEmail,
    founderStudentId,
    founderFaculty,
    avatarUrl,
    coverUrl,
    schedule,
    location,
    benefits,
    contactEmail,
    contactPhone,
    status,
    adminFeedback,
    reviewedBy,
    reviewedByName,
    reviewedAt,
    createdAt,
    updatedAt,
  ];
}
