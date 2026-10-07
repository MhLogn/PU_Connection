import 'package:equatable/equatable.dart';

class ClubEntity extends Equatable {
  final String id;
  final String name;
  final String category;
  final String description;
  final String avatarUrl;
  final String coverUrl;
  final String leaderId;
  final String leaderName;
  final List<String> memberIds;
  final int membersCount;
  final String schedule;
  final String location;
  final List<String> benefits;
  final String contactEmail;
  final String contactPhone;
  final int colorValue;

  const ClubEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.avatarUrl = '',
    this.coverUrl = '',
    this.leaderId = '',
    this.leaderName = '',
    this.memberIds = const [],
    this.membersCount = 0,
    this.schedule = 'Tối Thứ 4 & Chủ Nhật hàng tuần (18h30 - 20h30)',
    this.location = 'Tòa A9 (Phòng Hội thảo 2) & Sân thể thao Phenikaa',
    this.benefits = const [
      'Cộng điểm rèn luyện (ĐRL) tiêu chí Hoạt động phong trào',
      'Cấp chứng nhận thành viên và cơ hội thi đấu cấp toàn quốc',
    ],
    this.contactEmail = '',
    this.contactPhone = '',
    this.colorValue = 0xFF0284C7,
  });

  bool isMember(String userId) {
    if (userId.isEmpty) return false;
    return memberIds.contains(userId);
  }

  int get effectiveMembersCount =>
      membersCount > memberIds.length ? membersCount : memberIds.length;

  ClubEntity copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? leaderId,
    String? leaderName,
    List<String>? memberIds,
    int? membersCount,
    String? schedule,
    String? location,
    List<String>? benefits,
    String? contactEmail,
    String? contactPhone,
    int? colorValue,
  }) {
    return ClubEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      memberIds: memberIds ?? this.memberIds,
      membersCount: membersCount ?? this.membersCount,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      benefits: benefits ?? this.benefits,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        description,
        avatarUrl,
        coverUrl,
        leaderId,
        leaderName,
        memberIds,
        membersCount,
        schedule,
        location,
        benefits,
        contactEmail,
        contactPhone,
        colorValue,
      ];
}
