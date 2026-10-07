import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/club_entity.dart';

class ClubModel extends ClubEntity {
  const ClubModel({
    required super.id,
    required super.name,
    required super.category,
    required super.description,
    super.avatarUrl,
    super.coverUrl,
    super.leaderId,
    super.leaderName,
    super.memberIds,
    super.membersCount,
    super.schedule,
    super.location,
    super.benefits,
    super.contactEmail,
    super.contactPhone,
    super.colorValue,
  });

  factory ClubModel.fromMap(Map<String, dynamic> map, String id) {
    return ClubModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Học thuật',
      description: map['desc'] as String? ?? (map['description'] as String? ?? ''),
      avatarUrl: map['avatarUrl'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      leaderId: map['leaderId'] as String? ?? '',
      leaderName: map['leaderName'] as String? ?? 'Ban Chủ Nhiệm',
      memberIds: List<String>.from(map['members'] as List? ?? (map['memberIds'] as List? ?? [])),
      membersCount: (map['membersCount'] as num?)?.toInt() ?? 0,
      schedule: map['schedule'] as String? ?? 'Tối Thứ 4 & Chủ Nhật hàng tuần (18h30 - 20h30)',
      location: map['location'] as String? ?? 'Tòa A9 (Phòng Hội thảo 2) & Sân thể thao Phenikaa',
      benefits: List<String>.from(map['benefits'] as List? ?? [
        'Cộng điểm rèn luyện (ĐRL) tiêu chí Hoạt động phong trào',
        'Cấp chứng nhận thành viên và cơ hội thi đấu cấp toàn quốc',
      ]),
      contactEmail: map['contactEmail'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      colorValue: (map['color'] as num?)?.toInt() ?? ((map['colorValue'] as num?)?.toInt() ?? 0xFF0284C7),
    );
  }

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClubModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'desc': description,
      'description': description,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'members': memberIds,
      'memberIds': memberIds,
      'membersCount': effectiveMembersCount,
      'schedule': schedule,
      'location': location,
      'benefits': benefits,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'color': colorValue,
      'colorValue': colorValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
