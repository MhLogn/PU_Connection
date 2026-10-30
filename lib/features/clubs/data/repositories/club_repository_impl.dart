import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/club_creation_request_entity.dart';
import '../../domain/entities/club_entity.dart';
import '../../domain/repositories/club_repository.dart';
import '../models/club_creation_request_model.dart';
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

  static bool enableSeedClubs = false;
  static List<ClubEntity> get seedClubs =>
      enableSeedClubs ? defaultClubs : const <ClubEntity>[];
  static final List<ClubEntity> _memoryClubs = List<ClubEntity>.from(seedClubs);
  static final List<ClubCreationRequestEntity> _memoryClubRequests = [];
  static final StreamController<List<ClubEntity>> _memoryController =
      StreamController<List<ClubEntity>>.broadcast();
  static final StreamController<List<ClubCreationRequestEntity>>
  _memoryRequestsController =
      StreamController<List<ClubCreationRequestEntity>>.broadcast();

  static void resetMemory() {
    _memoryClubs.clear();
    _memoryClubRequests.clear();
    if (enableSeedClubs) {
      _memoryClubs.addAll(defaultClubs);
    }
  }

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
          'Đội tuyển và câu lạc bộ bóng rổ Đại học Phenikaa. Luyện tập thể lực bài bản, chiến thuật thi đấu và đại diện trường tham gia giải bóng rổ sinh viên toàn quốc (NUC) cùng các giải mở rộng Hà Nội.',
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
      colorValue: 0xFFFF7A00,
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
      colorValue: 0xFF0284C7,
    ),
  ];

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
            return seedClubs;
          }
          final list = snapshot.docs
              .map<ClubEntity>((doc) => ClubModel.fromFirestore(doc))
              .where((c) => c.status == 'approved')
              .toList();
          return list.isEmpty ? seedClubs : list;
        })
        .handleError((_) => seedClubs);
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
    final matches = seedClubs.where((c) => c.id == clubId);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<void> joinClub({
    required String clubId,
    required String userId,
  }) async {
    if (clubId.isEmpty || userId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId);

      try {
        final doc = await docRef.get();
        if (!doc.exists) {
          // Initialize doc with default attributes
          final matches = defaultClubs.where((c) => c.id == clubId);
          final defaultClub = matches.isNotEmpty
              ? matches.first
              : defaultClubs.first;
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
          final data = doc.data() ?? {};
          final currentMemberIds = List<String>.from(data['memberIds'] ?? data['members'] ?? []);
          if (currentMemberIds.contains(userId)) {
            return; // Đã là thành viên, tránh tăng đúp
          }
          await docRef.update({
            'members': FieldValue.arrayUnion([userId]),
            'memberIds': FieldValue.arrayUnion([userId]),
            'membersCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Tự động đồng bộ thêm thành viên vào nhóm chat CLB
          try {
            await firestore
                .collection(FirebaseConstants.chatsCollection)
                .doc('chat_club_$clubId')
                .update({
                  'participantIds': FieldValue.arrayUnion([userId]),
                });
          } catch (_) {}

          // Gửi thông báo đến Chủ nhiệm CLB nếu có thành viên mới gia nhập
          try {
            final leaderId = data['leaderId'] as String? ?? '';
            if (leaderId.isNotEmpty && leaderId != userId) {
              await firestore
                  .collection(FirebaseConstants.usersCollection)
                  .doc(leaderId)
                  .collection(FirebaseConstants.notificationsSubcollection)
                  .add({
                    'title': 'Thành viên mới gia nhập CLB 🎉',
                    'content': 'Có một sinh viên vừa tham gia câu lạc bộ "${data['name'] ?? 'của bạn'}".',
                    'body': 'Có một sinh viên vừa tham gia câu lạc bộ "${data['name'] ?? 'của bạn'}".',
                    'type': 'club_member_joined',
                    'targetId': clubId,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });
            }
          } catch (_) {}

          return;
        }
      } catch (e) {
        debugPrint('Error joining club on firestore: $e');
        rethrow;
      }
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
  Future<void> leaveClub({
    required String clubId,
    required String userId,
    String? secondaryId,
  }) async {
    if (clubId.isEmpty || userId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId);

      try {
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final currentMemberIds = List<String>.from(data['memberIds'] ?? data['members'] ?? []);
          final toRemove = <String>[userId];
          if (secondaryId != null && secondaryId.isNotEmpty && secondaryId != userId) {
            toRemove.add(secondaryId);
          }
          final isAnyMember = currentMemberIds.any((id) => toRemove.contains(id));
          if (!isAnyMember) {
            return; // Chưa là thành viên, không trừ âm
          }
          await docRef.update({
            'members': FieldValue.arrayRemove(toRemove),
            'memberIds': FieldValue.arrayRemove(toRemove),
            'membersCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Tự động đồng bộ xóa thành viên khỏi nhóm chat CLB
          try {
            await firestore
                .collection(FirebaseConstants.chatsCollection)
                .doc('chat_club_$clubId')
                .update({
                  'participantIds': FieldValue.arrayRemove(toRemove),
                });
          } catch (_) {}
        }
        return;
      } catch (e) {
        debugPrint('Error leaving club on firestore: $e');
        rethrow;
      }
    }

    for (int i = 0; i < _memoryClubs.length; i++) {
      final club = _memoryClubs[i];
      if (club.id == clubId) {
        final toRemove = <String>[userId];
        if (secondaryId != null && secondaryId.isNotEmpty && secondaryId != userId) {
          toRemove.add(secondaryId);
        }
        final isAnyMember = club.memberIds.any((id) => toRemove.contains(id));
        if (!isAnyMember) return;

        final updated = List<String>.from(club.memberIds)
          ..removeWhere((id) => toRemove.contains(id));
        _memoryClubs[i] = club.copyWith(
          memberIds: updated,
          membersCount: club.effectiveMembersCount > 0
              ? club.effectiveMembersCount - 1
              : 0,
        );
      }
    }
    _memoryController.add(List<ClubEntity>.from(_memoryClubs));
  }

  @override
  Future<void> updateClub(ClubEntity club) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final model = club is ClubModel
            ? club
            : ClubModel(
                id: club.id,
                name: club.name,
                category: club.category,
                description: club.description,
                avatarUrl: club.avatarUrl,
                coverUrl: club.coverUrl,
                leaderId: club.leaderId,
                leaderName: club.leaderName,
                memberIds: club.memberIds,
                membersCount: club.effectiveMembersCount,
                schedule: club.schedule,
                location: club.location,
                benefits: club.benefits,
                contactEmail: club.contactEmail,
                contactPhone: club.contactPhone,
                colorValue: club.colorValue,
                status: club.status,
              );
        await firestore
            .collection(FirebaseConstants.clubsCollection)
            .doc(club.id)
            .update(model.toMap());
      } catch (_) {}
    }

    for (int i = 0; i < _memoryClubs.length; i++) {
      if (_memoryClubs[i].id == club.id) {
        _memoryClubs[i] = club;
        break;
      }
    }
    _memoryController.add(List<ClubEntity>.from(_memoryClubs));
  }

  @override
  Stream<List<ClubCreationRequestEntity>> getClubRequestsStream({
    String? status,
    String? founderId,
  }) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emit() {
          var list = List<ClubCreationRequestEntity>.from(_memoryClubRequests);
          if (status != null && status.isNotEmpty) {
            list = list.where((r) => r.status == status).toList();
          }
          if (founderId != null && founderId.isNotEmpty) {
            list = list.where((r) => r.founderId == founderId).toList();
          }
          controller.add(list);
        }

        emit();
        final sub = _memoryRequestsController.stream.listen((_) => emit());
        controller.onCancel = () => sub.cancel();
      });
    }

    Query<Map<String, dynamic>> query = firestore.collection(
      FirebaseConstants.clubRequestsCollection,
    );

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (founderId != null && founderId.isNotEmpty) {
      query = query.where('founderId', isEqualTo: founderId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ClubCreationRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    }).handleError((_) => const <ClubCreationRequestEntity>[]);
  }

  @override
  Future<void> submitClubCreationRequest(ClubCreationRequestEntity request) async {
    final trimmedName = request.clubName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tên câu lạc bộ không được để trống.');
    }
    if (trimmedName.length < 4) {
      throw Exception('Tên câu lạc bộ phải có ít nhất 4 ký tự.');
    }
    final trimmedDesc = request.description.trim();
    if (trimmedDesc.isEmpty) {
      throw Exception('Mô tả câu lạc bộ không được để trống.');
    }
    if (trimmedDesc.length < 20) {
      throw Exception('Mô tả câu lạc bộ cần chi tiết hơn (ít nhất 20 ký tự).');
    }
    final trimmedReason = request.reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Lý do thành lập CLB không được để trống.');
    }
    if (trimmedReason.length < 15) {
      throw Exception('Lý do thành lập CLB cần cụ thể hơn (ít nhất 15 ký tự).');
    }
    if (request.founderId.isEmpty) {
      throw Exception('Vui lòng đăng nhập để gửi yêu cầu thành lập CLB.');
    }

    final firestore = _firestore;
    final docId = request.id.isNotEmpty
        ? request.id
        : (firestore != null
            ? firestore.collection(FirebaseConstants.clubRequestsCollection).doc().id
            : 'req_${DateTime.now().millisecondsSinceEpoch}');

    if (firestore != null) {
      // 1. Kiểm tra trùng tên với CLB chính thức đang hoạt động
      final existingClubSnap = await firestore
          .collection(FirebaseConstants.clubsCollection)
          .where('name', isEqualTo: trimmedName)
          .limit(1)
          .get();
      if (existingClubSnap.docs.isNotEmpty) {
        throw Exception(
          'Tên câu lạc bộ "$trimmedName" đã được đăng ký và đang hoạt động.',
        );
      }

      // 2. Kiểm tra trùng tên với yêu cầu đang chờ duyệt
      final pendingReqSnap = await firestore
          .collection(FirebaseConstants.clubRequestsCollection)
          .where('clubName', isEqualTo: trimmedName)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (pendingReqSnap.docs.isNotEmpty) {
        throw Exception(
          'Đã có yêu cầu thành lập CLB mang tên "$trimmedName" đang chờ Ban Quản trị phê duyệt.',
        );
      }

      final model = ClubCreationRequestModel(
        id: docId,
        clubName: trimmedName,
        category: request.category,
        description: trimmedDesc,
        reason: trimmedReason,
        founderId: request.founderId,
        founderName: request.founderName,
        founderEmail: request.founderEmail,
        founderStudentId: request.founderStudentId,
        founderFaculty: request.founderFaculty,
        avatarUrl: request.avatarUrl,
        coverUrl: request.coverUrl,
        schedule: request.schedule.trim(),
        location: request.location.trim(),
        benefits: request.benefits,
        contactEmail: request.contactEmail.trim(),
        contactPhone: request.contactPhone.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final docMap = model.toMap();
      docMap['createdAt'] = FieldValue.serverTimestamp();
      docMap['updatedAt'] = FieldValue.serverTimestamp();

      await firestore
          .collection(FirebaseConstants.clubRequestsCollection)
          .doc(docId)
          .set(docMap);
    }

    // In-memory update & duplicate check
    if (_memoryClubs.any((c) => c.name.toLowerCase() == trimmedName.toLowerCase())) {
      throw Exception('Tên câu lạc bộ "$trimmedName" đã tồn tại.');
    }
    if (_memoryClubRequests.any(
      (r) =>
          r.clubName.toLowerCase() == trimmedName.toLowerCase() &&
          r.status == 'pending',
    )) {
      throw Exception(
        'Đã có yêu cầu thành lập CLB "$trimmedName" đang chờ phê duyệt.',
      );
    }

    _memoryClubRequests.insert(
      0,
      request.copyWith(
        id: docId,
        clubName: trimmedName,
        description: trimmedDesc,
        reason: trimmedReason,
        createdAt: DateTime.now(),
        status: 'pending',
      ),
    );
    _memoryRequestsController.add(List.from(_memoryClubRequests));
  }

  @override
  Future<void> reviewClubRequest({
    required String requestId,
    required String action,
    String? rejectionReason,
    required String adminId,
    required String adminName,
  }) async {
    final firestore = _firestore;
    final isApprove = action.toLowerCase() == 'approve';

    if (firestore != null) {
      final reqRef = firestore
          .collection(FirebaseConstants.clubRequestsCollection)
          .doc(requestId);
      final reqDoc = await reqRef.get();
      if (!reqDoc.exists) {
        throw Exception('Không tìm thấy yêu cầu thành lập câu lạc bộ.');
      }

      final reqData = reqDoc.data() ?? {};
      final reqModel = ClubCreationRequestModel.fromMap(reqData, reqDoc.id);

      if (isApprove) {
        // Approve: 1. Update request status -> approved
        await reqRef.update({
          'status': 'approved',
          'reviewedBy': adminId,
          'reviewedByName': adminName,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Create official Club document in clubs
        final clubId = reqModel.id.startsWith('req_')
            ? 'club_${reqModel.id.substring(4)}'
            : 'club_${reqModel.id}';
        final newClub = ClubModel(
          id: clubId,
          name: reqModel.clubName,
          category: reqModel.category,
          description: reqModel.description,
          avatarUrl: reqModel.avatarUrl,
          coverUrl: reqModel.coverUrl,
          leaderId: reqModel.founderId,
          leaderName: reqModel.founderName,
          memberIds: [reqModel.founderId],
          membersCount: 1,
          schedule: reqModel.schedule,
          location: reqModel.location,
          benefits: reqModel.benefits,
          contactEmail: reqModel.contactEmail,
          contactPhone: reqModel.contactPhone,
          status: 'approved',
        );

        await firestore
            .collection(FirebaseConstants.clubsCollection)
            .doc(clubId)
            .set(newClub.toMap());

        // 2.1 Tự động tạo nhóm chat chính thức cho Câu lạc bộ
        try {
          final groupChatId = 'chat_club_$clubId';
          final chatDocRef = firestore
              .collection(FirebaseConstants.chatsCollection)
              .doc(groupChatId);
          final existingChat = await chatDocRef.get();
          if (!existingChat.exists) {
            await chatDocRef.set({
              'participantIds': [reqModel.founderId],
              'participantNames': {reqModel.founderId: reqModel.founderName},
              'participantAvatars': {reqModel.founderId: reqModel.avatarUrl},
              'participantFaculties': {reqModel.founderId: reqModel.founderFaculty},
              'lastMessage':
                  'Nhóm chat chính thức của CLB ${reqModel.clubName} đã được kích hoạt.',
              'lastMessageSenderId': adminId,
              'lastMessageAt': FieldValue.serverTimestamp(),
              'unreadCounts': {reqModel.founderId: 0},
              'isGroup': true,
              'groupName': 'CLB ${reqModel.clubName}',
              'groupAvatar': reqModel.avatarUrl,
              'adminId': reqModel.founderId,
              'clubId': clubId,
            });

            await chatDocRef
                .collection(FirebaseConstants.messagesSubcollection)
                .add({
                  'senderId': adminId,
                  'senderName': adminName,
                  'senderAvatar': '',
                  'senderFaculty': 'Ban Quản trị',
                  'content':
                      'Chào mừng các thành viên đến với không gian trò chuyện của CLB ${reqModel.clubName}! Chúc câu lạc bộ hoạt động sôi nổi và gặt hái nhiều thành công.',
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                  'type': 'system',
                });
          }
        } catch (e) {
          debugPrint('Error auto-creating club group chat: $e');
        }

        // 3. Send congratulation notification to founder
        try {
          await firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(reqModel.founderId)
              .collection(FirebaseConstants.notificationsSubcollection)
              .add({
                'title': 'Câu lạc bộ đã được phê duyệt! 🎉',
                'content':
                    'Đề xuất thành lập "${reqModel.clubName}" của bạn đã được Ban Quản trị phê duyệt chính thức.',
                'body':
                    'Đề xuất thành lập "${reqModel.clubName}" của bạn đã được Ban Quản trị phê duyệt chính thức.',
                'type': 'club_approved',
                'targetId': clubId,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        } catch (_) {}

        // 4. Record Admin Audit Log
        try {
          await firestore
              .collection(FirebaseConstants.auditLogsCollection)
              .add({
                'adminId': adminId,
                'adminEmail': adminName,
                'action': 'approve_club_proposal',
                'targetType': 'club_proposal',
                'targetId': requestId,
                'details':
                    'Phê duyệt thành lập CLB "${reqModel.clubName}" (Chủ nhiệm: ${reqModel.founderName})',
                'createdAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {}
      } else {
        // Reject: Update request status -> rejected with reason
        await reqRef.update({
          'status': 'rejected',
          'adminFeedback': rejectionReason ?? 'Không phù hợp định hướng hoạt động',
          'reviewedBy': adminId,
          'reviewedByName': adminName,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send rejection notice to founder
        try {
          await firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(reqModel.founderId)
              .collection(FirebaseConstants.notificationsSubcollection)
              .add({
                'title': 'Yêu cầu thành lập CLB chưa được duyệt',
                'content':
                    'Đề xuất "${reqModel.clubName}" chưa được duyệt. Lý do: ${rejectionReason ?? "Chưa đáp ứng tiêu chí"}',
                'body':
                    'Đề xuất "${reqModel.clubName}" chưa được duyệt. Lý do: ${rejectionReason ?? "Chưa đáp ứng tiêu chí"}',
                'type': 'club_rejected',
                'targetId': requestId,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        } catch (_) {}

        // Record Admin Audit Log
        try {
          await firestore
              .collection(FirebaseConstants.auditLogsCollection)
              .add({
                'adminId': adminId,
                'adminEmail': adminName,
                'action': 'reject_club_proposal',
                'targetType': 'club_proposal',
                'targetId': requestId,
                'details':
                    'Từ chối thành lập CLB "${reqModel.clubName}". Lý do: ${rejectionReason ?? "Chưa đáp ứng tiêu chí"}',
                'createdAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {}
      }
    }

    // In-memory update
    final reqIndex = _memoryClubRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex >= 0) {
      final currentReq = _memoryClubRequests[reqIndex];
      if (isApprove) {
        _memoryClubRequests[reqIndex] = currentReq.copyWith(
          status: 'approved',
          reviewedBy: adminId,
          reviewedByName: adminName,
          reviewedAt: DateTime.now(),
        );

        final newClub = ClubEntity(
          id: 'club_${currentReq.id}',
          name: currentReq.clubName,
          category: currentReq.category,
          description: currentReq.description,
          avatarUrl: currentReq.avatarUrl,
          coverUrl: currentReq.coverUrl,
          leaderId: currentReq.founderId,
          leaderName: currentReq.founderName,
          memberIds: [currentReq.founderId],
          membersCount: 1,
          schedule: currentReq.schedule,
          location: currentReq.location,
          benefits: currentReq.benefits,
          contactEmail: currentReq.contactEmail,
          contactPhone: currentReq.contactPhone,
          status: 'approved',
        );
        _memoryClubs.add(newClub);
        _memoryController.add(List.from(_memoryClubs));
      } else {
        _memoryClubRequests[reqIndex] = currentReq.copyWith(
          status: 'rejected',
          adminFeedback: rejectionReason,
          reviewedBy: adminId,
          reviewedByName: adminName,
          reviewedAt: DateTime.now(),
        );
      }
      _memoryRequestsController.add(List.from(_memoryClubRequests));
    }
  }

  @override
  Future<void> cancelClubRequest(String requestId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.clubRequestsCollection)
            .doc(requestId)
            .delete();
      } catch (_) {}
    }
    _memoryClubRequests.removeWhere((r) => r.id == requestId);
    _memoryRequestsController.add(List.from(_memoryClubRequests));
  }
}
