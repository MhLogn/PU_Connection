import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/club_entity.dart';
import '../../domain/repositories/club_repository.dart';
import '../models/club_model.dart';

class ClubRepositoryImpl implements ClubRepository {
  final FirebaseFirestore? _customFirestore;

  ClubRepositoryImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  static final List<ClubEntity> _memoryClubs = List<ClubEntity>.from(defaultClubs);

  static List<ClubEntity> get defaultClubs => const [
    ClubEntity(
      id: 'club_pro_it',
      name: 'CLB Tin Học Phenikaa PRO',
      category: 'Học thuật',
      description:
          'Cộng đồng sinh viên đam mê lập trình phần mềm, thuật toán, an toàn thông tin & AI tại Đại học Phenikaa. Nơi tổ chức các buổi tech talk, workshop thực chiến và ôn luyện thi Phenikaa IT Hackathon.',
      leaderName: 'Nguyễn Tiến Dũng (K16 CNTT)',
      membersCount: 480,
      memberIds: ['23010390', '23010001', '23010002'],
      schedule: 'Tối Thứ 4 (19h00) & Chiều Thứ 7 (14h00)',
      location: 'Phòng Lab Tầng 4 - Tòa A9 (Phenikaa Innovation Hub)',
      benefits: [
        'Cộng điểm rèn luyện (ĐRL) tiêu chí Học thuật & Phong trào',
        'Thực chiến dự án thực tế cùng các mentors doanh nghiệp Phenikaa-X',
        'Ưu tiên giới thiệu thực tập tại các đối tác công nghệ lớn',
      ],
      contactEmail: 'proclub@st.phenikaa-uni.edu.vn',
      contactPhone: '0981 234 567',
      colorValue: 0xFF0284C7,
    ),
    ClubEntity(
      id: 'club_pec_english',
      name: 'Phenikaa English Club (PEC)',
      category: 'Học thuật',
      description:
          'Môi trường rèn luyện giao tiếp tiếng Anh 100% tự nhiên, các buổi Public Speaking, câu lạc bộ sách, workshop chuẩn bị chứng chỉ IELTS/TOEIC và chia sẻ kinh nghiệm săn học bổng du học toàn cầu.',
      leaderName: 'Trần Mai Linh (K17 Ngôn ngữ Anh)',
      membersCount: 620,
      memberIds: ['23010001'],
      schedule: 'Sáng Chủ Nhật hàng tuần (08h30 - 11h00)',
      location: 'Quảng trường Tòa A2 - Không gian xanh Phenikaa',
      benefits: [
        'Tự tin giao tiếp tiếng Anh trôi chảy trong môi trường đại học',
        'Cộng 5 - 8 điểm rèn luyện mỗi kỳ tham gia tích cực',
        'Tea break miễn phí và kết nối với các bạn bè quốc tế',
      ],
      contactEmail: 'pec@st.phenikaa-uni.edu.vn',
      contactPhone: '0978 888 999',
      colorValue: 0xFF0284C7,
    ),
    ClubEntity(
      id: 'club_pgc_guitar',
      name: 'Phenikaa Guitar & Acoustic Club (PGC)',
      category: 'Nghệ thuật',
      description:
          'Nơi hội tụ những tâm hồn yêu âm nhạc acoustic, guitar, piano và thanh nhạc. Ban nhạc biểu diễn chính trong các đêm Gala Chào Tân sinh viên, Đêm nhạc Acoustic Night và hội diễn văn nghệ cấp Trường.',
      leaderName: 'Lê Hoàng Nam (K16 Cơ điện tử)',
      membersCount: 350,
      memberIds: [],
      schedule: 'Tối Thứ 3 & Thứ 6 hàng tuần (18h00 - 20h30)',
      location: 'Hội trường Tầng 3 - Tòa A9 & Sân trường A2',
      benefits: [
        'Học đàn guitar, cajon và luyện thanh nhạc hoàn toàn miễn phí',
        'Cơ hội đứng trên sân khấu lớn trước hàng nghìn sinh viên',
        'Cộng điểm rèn luyện tiêu chí Văn thể mỹ',
      ],
      contactEmail: 'pgc@st.phenikaa-uni.edu.vn',
      contactPhone: '0912 345 678',
      colorValue: 0xFFFF7A00,
    ),
    ClubEntity(
      id: 'club_basketball',
      name: 'Phenikaa Basketball Club (PBC)',
      category: 'Thể thao',
      description:
          'Đội tuyển và câu lạc bộ bóng rổ trường Đại học Phenikaa. Luyện tập thể lực bài bản, chiến thuật thi đấu và đại diện trường tham gia giải bóng rổ sinh viên toàn quốc (NUC) cùng các giải mở rộng Hà Nội.',
      leaderName: 'Phạm Đức Anh (K17 Kỹ thuật Ô tô)',
      membersCount: 290,
      memberIds: ['23010002'],
      schedule: 'Chiều Thứ 2, Thứ 5 & Thứ 7 (16h30 - 18h30)',
      location: 'Nhà thi đấu đa năng & Sân bóng rổ ngoài trời Tòa A8',
      benefits: [
        'Nâng cao thể lực, sức bền và kỹ năng chơi bóng rổ chuẩn mực',
        'Áo đấu và trang thiết bị luyện tập được CLB hỗ trợ',
        'Cộng điểm rèn luyện thể chất tối đa (8 ĐRL/kỳ)',
      ],
      contactEmail: 'pbc@st.phenikaa-uni.edu.vn',
      contactPhone: '0933 666 777',
      colorValue: 0xFFE11D48,
    ),
    ClubEntity(
      id: 'club_volunteer_green',
      name: 'Đội Sinh Viên Tình Nguyện PU',
      category: 'Tình nguyện',
      description:
          'Đội tình nguyện xung kích trực thuộc Đoàn Thanh niên & Hội Sinh viên Phenikaa. Tổ chức các chiến dịch: Tiếp sức mùa thi, Mùa hè xanh, Ngày thứ Bảy tình nguyện, Hiến máu nhân đạo và hỗ trợ tân sinh viên K18.',
      leaderName: 'Hoàng Thu Trang (K16 Quản trị Kinh doanh)',
      membersCount: 540,
      memberIds: ['23010390', '23010003'],
      schedule: 'Họp định kỳ tối Thứ 7 & Các đợt chiến dịch cao điểm',
      location: 'Văn phòng Đoàn TN - Tòa A9 (Phòng 204)',
      benefits: [
        'Cấp Giấy chứng nhận Tình nguyện viên cấp Trường / Cấp Thành đoàn',
        'Cộng điểm rèn luyện tối đa (10 ĐRL/kỳ)',
        'Rèn luyện kỹ năng mềm, tổ chức sự kiện và làm việc nhóm thực thụ',
      ],
      contactEmail: 'tinhnguyen@st.phenikaa-uni.edu.vn',
      contactPhone: '0904 111 222',
      colorValue: 0xFF10B981,
    ),
  ];

  static final StreamController<List<ClubEntity>> _memoryController =
      StreamController<List<ClubEntity>>.broadcast();

  @override
  Stream<List<ClubEntity>> getClubsStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        controller.add(List<ClubEntity>.from(_memoryClubs));
        final sub = _memoryController.stream.listen((data) {
          controller.add(List<ClubEntity>.from(data));
        });
        controller.onCancel = () => sub.cancel();
      });
    }
    return firestore
        .collection(FirebaseConstants.clubsCollection)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultClubs;
      }
      return snapshot.docs.map((doc) => ClubModel.fromFirestore(doc)).toList();
    }).handleError((_) => defaultClubs);
  }

  @override
  Future<ClubEntity?> getClubById(String clubId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc = await firestore
            .collection(FirebaseConstants.clubsCollection)
            .doc(clubId)
            .get();
        if (doc.exists) {
          return ClubModel.fromFirestore(doc);
        }
      } catch (_) {}
    }

    // Fallback to default
    try {
      return defaultClubs.firstWhere((c) => c.id == clubId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> joinClub({required String clubId, required String userId}) async {
    if (clubId.isEmpty || userId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);

      try {
        final doc = await docRef.get();
        if (!doc.exists) {
          // Initialize doc with default attributes
          final defaultClub = defaultClubs.firstWhere(
            (c) => c.id == clubId,
            orElse: () => defaultClubs.first,
          );
          final members = Set<String>.from(defaultClub.memberIds)..add(userId);
          await docRef.set({
            'name': defaultClub.name,
            'category': defaultClub.category,
            'desc': defaultClub.description,
            'description': defaultClub.description,
            'leaderName': defaultClub.leaderName,
            'members': members.toList(),
            'memberIds': members.toList(),
            'membersCount': defaultClub.effectiveMembersCount + 1,
            'schedule': defaultClub.schedule,
            'location': defaultClub.location,
            'benefits': defaultClub.benefits,
            'contactEmail': defaultClub.contactEmail,
            'contactPhone': defaultClub.contactPhone,
            'color': defaultClub.colorValue,
            'colorValue': defaultClub.colorValue,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        } else {
          await docRef.update({
            'members': FieldValue.arrayUnion([userId]),
            'memberIds': FieldValue.arrayUnion([userId]),
            'membersCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
      } catch (_) {}
    }

    // In-memory fallback
    for (int i = 0; i < _memoryClubs.length; i++) {
      final club = _memoryClubs[i];
      if (club.id == clubId && !club.memberIds.contains(userId)) {
        _memoryClubs[i] = club.copyWith(
          memberIds: [...club.memberIds, userId],
          membersCount: club.effectiveMembersCount + 1,
        );
      }
    }
    _memoryController.add(List<ClubEntity>.from(_memoryClubs));
  }

  @override
  Future<void> leaveClub({required String clubId, required String userId}) async {
    if (clubId.isEmpty || userId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);

      try {
        await docRef.update({
          'members': FieldValue.arrayRemove([userId]),
          'memberIds': FieldValue.arrayRemove([userId]),
          'membersCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      } catch (_) {}
    }

    for (int i = 0; i < _memoryClubs.length; i++) {
      final club = _memoryClubs[i];
      if (club.id == clubId) {
        final updated = List<String>.from(club.memberIds)..remove(userId);
        _memoryClubs[i] = club.copyWith(
          memberIds: updated,
          membersCount: club.effectiveMembersCount > 0 ? club.effectiveMembersCount - 1 : 0,
        );
      }
    }
    _memoryController.add(List<ClubEntity>.from(_memoryClubs));
  }
}
