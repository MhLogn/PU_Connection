import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/study_group_entity.dart';
import '../../domain/repositories/study_group_repository.dart';
import '../models/study_group_model.dart';

class StudyGroupRepositoryImpl implements StudyGroupRepository {
  final FirebaseFirestore? _firestore;

  // In-memory store cho test/offline
  final List<StudyGroupEntity> _inMemoryGroups = [];
  final StreamController<List<StudyGroupEntity>> _controller =
      StreamController<List<StudyGroupEntity>>.broadcast();

  StudyGroupRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore {
    _initSeedData();
  }

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  void _initSeedData() {
    final now = DateTime.now();
    _inMemoryGroups.addAll([
      StudyGroupEntity(
        id: 'group_math_01',
        creatorId: 'sv_math_lead',
        creatorName: 'Đặng Tuấn Anh',
        creatorStudentId: '22010156',
        creatorFaculty: 'Khoa Công nghệ thông tin',
        title: 'Ôn thi cấp tốc Giải tích 2 (Kỳ phụ & Cải thiện điểm)',
        subject: 'Giải tích 2',
        description:
            'Nhóm tập trung giải các dạng đề thi trắc nghiệm & tự luận tích phân bội, phương trình vi phân. Đã có tài liệu ôn tập chuẩn từ thầy cô.',
        maxMembers: 5,
        memberIds: const ['sv_math_lead', '23010390', '22010888'],
        pendingRequestIds: const [],
        studyTime: now.add(const Duration(days: 2, hours: 4)),
        location: 'Phòng tự học Tầng 3 - Thư viện Tòa A9',
        createdAt: now.subtract(const Duration(hours: 12)),
        isOpen: true,
      ),
      StudyGroupEntity(
        id: 'group_flutter_02',
        creatorId: 'sv_dev_01',
        creatorName: 'Lê Minh Quân',
        creatorStudentId: '22010452',
        creatorFaculty: 'Khoa Công nghệ thông tin',
        title: 'Team Lập trình Mobile Flutter - Dự án PU Connection',
        subject: 'Lập trình Mobile',
        description:
            'Cùng nhau code Clean Architecture, State Management BLoC và kết nối Firebase / Cloudinary. Hoan nghênh các bạn K16, K17!',
        maxMembers: 4,
        memberIds: const ['sv_dev_01', 'sv_dev_02'],
        pendingRequestIds: const [],
        studyTime: now.add(const Duration(days: 1, hours: 2)),
        location: 'Phenikaa Maker Space - Tòa A2',
        createdAt: now.subtract(const Duration(days: 1)),
        isOpen: true,
      ),
      StudyGroupEntity(
        id: 'group_english_03',
        creatorId: 'sv_eng_lead',
        creatorName: 'Trần Thảo Linh',
        creatorStudentId: '23010214',
        creatorFaculty: 'Khoa Ngoại ngữ & Du lịch',
        title: 'Luyện đề TOEIC 650+ chuẩn đầu ra tốt nghiệp Phenikaa',
        subject: 'Tiếng Anh B1 / TOEIC',
        description:
            'Mỗi buổi cùng bấm giờ giải 1 đề Listening + Reading, sau đó chữa chi tiết từ vựng và bẫy đề thi. Học đều đặn thứ 3 và thứ 6.',
        maxMembers: 6,
        memberIds: const ['sv_eng_lead', 'sv_eng_02', 'sv_eng_03', 'sv_eng_04'],
        pendingRequestIds: const [],
        studyTime: now.add(const Duration(days: 3, hours: 6)),
        location: 'Online qua Google Meet',
        createdAt: now.subtract(const Duration(days: 2)),
        isOpen: true,
      ),
      StudyGroupEntity(
        id: 'group_econ_04',
        creatorId: 'sv_econ_lead',
        creatorName: 'Phạm Hoàng Nam',
        creatorStudentId: '23010678',
        creatorFaculty: 'Khoa Kinh tế & Kinh doanh',
        title: 'Nhóm học Kinh tế Vi mô & Xác suất Thống kê',
        subject: 'Kinh tế Vi mô',
        description:
            'Giải bài tập mô hình cung cầu, thặng dư tiêu dùng và bài tập xác suất phân phối nhị thức. Chuẩn bị cho kỳ thi giữa kỳ.',
        maxMembers: 5,
        memberIds: const ['sv_econ_lead'],
        pendingRequestIds: const [],
        studyTime: now.add(const Duration(days: 4, hours: 3)),
        location: 'Khu tự học Tòa A8',
        createdAt: now.subtract(const Duration(days: 3)),
        isOpen: true,
      ),
    ]);
  }

  void _notify() {
    _controller.add(List.unmodifiable(_inMemoryGroups));
  }

  @override
  Stream<List<StudyGroupEntity>> watchStudyGroups({String? subject}) {
    final db = _db;
    if (db == null) {
      Timer.run(() => _notify());
      return _controller.stream.map((groups) {
        if (subject == null || subject.isEmpty || subject == 'Tất cả') {
          return groups;
        }
        return groups.where((g) => g.subject == subject).toList();
      });
    }

    try {
      Query query = db
          .collection(FirebaseConstants.studyGroupsCollection)
          .orderBy('createdAt', descending: true);

      if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
        query = query.where('subject', isEqualTo: subject);
      }

      return query
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return const <StudyGroupEntity>[];
            }

            final list = snapshot.docs
                .map<StudyGroupEntity>(
                  (doc) => StudyGroupModel.fromSnapshot(doc),
                )
                .toList();
            return list;
          })
          .handleError((_) {
            return const <StudyGroupEntity>[];
          });
    } catch (_) {
      Timer.run(() => _notify());
      return _controller.stream;
    }
  }

  @override
  Future<List<StudyGroupEntity>> getStudyGroups({String? subject}) async {
    final db = _db;
    if (db != null) {
      try {
        Query query = db
            .collection(FirebaseConstants.studyGroupsCollection)
            .orderBy('createdAt', descending: true);

        if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
          query = query.where('subject', isEqualTo: subject);
        }

        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map<StudyGroupEntity>((doc) => StudyGroupModel.fromSnapshot(doc))
              .toList();
        } else {
          return const <StudyGroupEntity>[];
        }
      } catch (_) {
        return const <StudyGroupEntity>[];
      }
    }

    if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
      return _inMemoryGroups.where((g) => g.subject == subject).toList();
    }
    return _inMemoryGroups;
  }

  @override
  Future<void> createStudyGroup(StudyGroupEntity group) async {
    // 1. In-memory
    _inMemoryGroups.removeWhere((g) => g.id == group.id);
    _inMemoryGroups.insert(0, group);
    _notify();

    // 2. Firestore
    final db = _db;
    if (db != null) {
      try {
        final model = StudyGroupModel.fromEntity(group);
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(group.id)
            .set(model.toMap());
      } catch (_) {}
    }
  }

  @override
  Future<void> requestToJoin(String groupId, String userId) async {
    final index = _inMemoryGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final g = _inMemoryGroups[index];
      if (!g.pendingRequestIds.contains(userId) &&
          !g.memberIds.contains(userId)) {
        final updatedRequests = List<String>.from(g.pendingRequestIds)
          ..add(userId);
        _inMemoryGroups[index] = g.copyWith(pendingRequestIds: updatedRequests);
        _notify();
      }
    }

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(groupId)
            .update({
              'pendingRequestIds': FieldValue.arrayUnion([userId]),
            });
      } catch (_) {}
    }
  }

  @override
  Future<void> cancelRequest(String groupId, String userId) async {
    final index = _inMemoryGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final g = _inMemoryGroups[index];
      final updatedRequests = List<String>.from(g.pendingRequestIds)
        ..remove(userId);
      _inMemoryGroups[index] = g.copyWith(pendingRequestIds: updatedRequests);
      _notify();
    }

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(groupId)
            .update({
              'pendingRequestIds': FieldValue.arrayRemove([userId]),
            });
      } catch (_) {}
    }
  }

  @override
  Future<void> acceptRequest(String groupId, String userId) async {
    final index = _inMemoryGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final g = _inMemoryGroups[index];
      final updatedRequests = List<String>.from(g.pendingRequestIds)
        ..remove(userId);
      final updatedMembers = List<String>.from(g.memberIds);
      if (!updatedMembers.contains(userId)) updatedMembers.add(userId);

      _inMemoryGroups[index] = g.copyWith(
        pendingRequestIds: updatedRequests,
        memberIds: updatedMembers,
      );
      _notify();
    }

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(groupId)
            .update({
              'pendingRequestIds': FieldValue.arrayRemove([userId]),
              'memberIds': FieldValue.arrayUnion([userId]),
            });
      } catch (_) {}
    }
  }

  @override
  Future<void> rejectRequest(String groupId, String userId) async {
    await cancelRequest(groupId, userId);
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    final index = _inMemoryGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final g = _inMemoryGroups[index];
      final updatedMembers = List<String>.from(g.memberIds)..remove(userId);
      _inMemoryGroups[index] = g.copyWith(memberIds: updatedMembers);
      _notify();
    }

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(groupId)
            .update({
              'memberIds': FieldValue.arrayRemove([userId]),
            });
      } catch (_) {}
    }
  }

  @override
  Future<void> closeGroup(String groupId) async {
    final index = _inMemoryGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _inMemoryGroups[index] = _inMemoryGroups[index].copyWith(isOpen: false);
      _notify();
    }

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.studyGroupsCollection)
            .doc(groupId)
            .update({'isOpen': false});
      } catch (_) {}
    }
  }
}
