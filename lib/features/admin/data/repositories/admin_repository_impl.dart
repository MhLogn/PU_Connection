import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../auth/data/datasources/phenikaa_student_directory.dart';
import '../../../auth/data/models/phenikaa_student_model.dart';
import '../../../auth/domain/entities/phenikaa_student_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../moderation/domain/entities/report_entity.dart';
import '../../../moderation/data/models/report_model.dart';
import '../../../moderation/domain/entities/report_reason.dart';
import '../../../moderation/domain/entities/report_target_type.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_audit_log_entity.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  AdminRepositoryImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _customFirestore = firestore,
      _customAuth = auth;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseAuth.instance;
      } catch (_) {}
    }
    return null;
  }

  // --- In-memory fallback stores for offline use & unit testing ---
  static final List<ReportEntity> _memoryReports = [];
  static final List<UserEntity> _memoryUsers = [];
  static final List<DocumentEntity> _memoryDocuments = [];
  static final List<AdminAuditLogEntity> _memoryAuditLogs = [];
  static final List<PhenikaaStudentEntity> _memoryPhenikaaStudents = [];
  static bool _initialized = false;
  static bool enableSeeds = false;

  static void resetMemory() {
    _memoryReports.clear();
    _memoryUsers.clear();
    _memoryDocuments.clear();
    _memoryAuditLogs.clear();
    _memoryPhenikaaStudents.clear();
    _initialized = false;
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    if (_memoryPhenikaaStudents.isEmpty) {
      _memoryPhenikaaStudents.addAll(PhenikaaStudentDirectory.defaultStudents);
    }

    // Seed admin user
    if (_memoryUsers.isEmpty) {
      _memoryUsers.add(
        const UserEntity(
          uid: 'admin_phenikaa_01',
          email: 'admin@phenikaa-uni.edu.vn',
          displayName: 'Ban Quản trị Phenikaa',
          studentId: 'ADMIN-01',
          faculty: 'Phòng Công tác Sinh viên',
          userType: 'admin',
          isVerified: true,
        ),
      );

      if (enableSeeds) {
        _memoryUsers.addAll(
          PhenikaaStudentDirectory.defaultStudents.map((s) {
            return UserEntity(
              uid: 'user_${s.studentId}',
              email: s.email,
              displayName: s.fullName,
              studentId: s.studentId,
              faculty: s.faculty,
              major: s.major,
              cohort: s.cohort,
              userType: 'student',
              isVerified: true,
              friendsCount: 15,
              postsCount: 3,
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
            );
          }),
        );
      }
    }

    if (!enableSeeds) return;

    // Seed realistic moderation reports
    if (_memoryReports.isEmpty) {
      _memoryReports.addAll([
        ReportEntity(
          id: 'rep_001',
          reporterId: 'user_23010390',
          reporterName: 'Hà Mạnh Long',
          targetId: 'post_violating_01',
          targetType: ReportTargetType.post,
          targetAuthorId: 'user_23010111',
          targetAuthorName: 'Nguyễn Hoàng Nam',
          reason: ReportReason.academicDishonesty,
          details: 'Quảng cáo dịch vụ làm hộ đồ án tốt nghiệp trong kỳ thi.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        ReportEntity(
          id: 'rep_002',
          reporterId: 'user_23010390',
          reporterName: 'Hà Mạnh Long',
          targetId: 'comment_violating_02',
          targetType: ReportTargetType.comment,
          targetAuthorId: 'user_22010222',
          targetAuthorName: 'Trần Thị Thanh Mai',
          reason: ReportReason.harassment,
          details: 'Bình luận xúc phạm và công kích cá nhân sinh viên khác.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        ReportEntity(
          id: 'rep_003',
          reporterId: 'user_22010222',
          reporterName: 'Trần Thị Thanh Mai',
          targetId: 'post_violating_03',
          targetType: ReportTargetType.post,
          targetAuthorId: 'user_23020015',
          targetAuthorName: 'Vũ Đức Thắng',
          reason: ReportReason.spam,
          details: 'Spam link web cá độ cờ bạc ngoài khuôn viên trường.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ]);
    }

    if (enableSeeds && _memoryDocuments.isEmpty) {
      _memoryDocuments.addAll([
        DocumentEntity(
          id: 'doc_admin_01',
          title: 'Giáo trình Giải tích 1 & 2 Chuẩn Phenikaa',
          code: 'MAT101',
          faculty: 'Khoa Khoa học Cơ bản',
          fileUrl: 'https://example.com/giai_tich.pdf',
          fileType: 'pdf',
          fileSize: '4.2 MB',
          authorId: 'admin_phenikaa_01',
          authorName: 'Bộ môn Toán',
          authorStudentId: 'KHCB-01',
          downloads: 342,
          rating: 4.9,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        DocumentEntity(
          id: 'doc_admin_02',
          title: 'Slide bài giảng Lập trình Hướng đối tượng OOP (C++)',
          code: 'CNTT202',
          faculty: 'Khoa Công nghệ Thông tin',
          fileUrl: 'https://example.com/oop_cpp.pdf',
          fileType: 'pdf',
          fileSize: '8.5 MB',
          authorId: 'user_21010001',
          authorName: 'Nguyễn Văn An',
          authorStudentId: '21010001',
          downloads: 189,
          rating: 4.8,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        DocumentEntity(
          id: 'doc_admin_03',
          title: 'Tài liệu không rõ nguồn gốc vi phạm bản quyền',
          code: 'SPAM101',
          faculty: 'Khoa Kinh tế và Quản trị',
          fileUrl: 'https://example.com/spam.pdf',
          fileType: 'pdf',
          fileSize: '1.1 MB',
          authorId: 'user_21010005',
          authorName: 'Lê Hoàng Long',
          authorStudentId: '21010005',
          downloads: 2,
          rating: 1.0,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    _ensureInitialized();
    final firestore = _firestore;

    if (firestore != null) {
      try {
        // Tối ưu hóa hiệu năng & chi phí: Sử dụng count() aggregation query
        // thay vì tải toàn bộ tài liệu về client
        final usersCountSnap = await firestore
            .collection(FirebaseConstants.usersCollection)
            .count()
            .get();
        final postsCountSnap = await firestore
            .collection(FirebaseConstants.postsCollection)
            .count()
            .get();
        final docsCountSnap = await firestore
            .collection(FirebaseConstants.studyDocumentsCollection)
            .count()
            .get();
        final reportsCountSnap = await firestore
            .collection(FirebaseConstants.reportsCollection)
            .where('status', isEqualTo: 'pending')
            .count()
            .get();
        final bannedCountSnap = await firestore
            .collection(FirebaseConstants.usersCollection)
            .where('isBanned', isEqualTo: true)
            .count()
            .get();

        // Lấy mẫu thống kê phân bổ khoa với limit an toàn
        final sampleUsersSnap = await firestore
            .collection(FirebaseConstants.usersCollection)
            .limit(200)
            .get();

        final facultyMap = <String, int>{};
        for (final doc in sampleUsersSnap.docs) {
          final data = doc.data();
          final fac = data['faculty'] as String? ?? 'Chưa xác định';
          facultyMap[fac] = (facultyMap[fac] ?? 0) + 1;
        }

        return AdminDashboardStats(
          totalStudents: usersCountSnap.count ?? sampleUsersSnap.docs.length,
          totalPosts: postsCountSnap.count ?? 0,
          totalDocuments: docsCountSnap.count ?? 0,
          pendingReports: reportsCountSnap.count ?? 0,
          bannedUsersCount: bannedCountSnap.count ?? 0,
          facultyDistribution: facultyMap,
        );
      } catch (_) {}
    }

    // Fallback to in-memory stats
    final facultyMap = <String, int>{};
    int bannedCount = 0;
    for (final u in _memoryUsers) {
      final fac = u.faculty.isNotEmpty ? u.faculty : 'Khoa CNTT';
      facultyMap[fac] = (facultyMap[fac] ?? 0) + 1;
      if (u.isBanned) bannedCount++;
    }

    final pending = _memoryReports.where((r) => r.status == 'pending').length;

    return AdminDashboardStats(
      totalStudents: _memoryUsers.length,
      totalPosts: 28,
      totalDocuments: _memoryDocuments.length,
      pendingReports: pending,
      bannedUsersCount: bannedCount,
      facultyDistribution: facultyMap,
    );
  }

  @override
  Future<List<ReportEntity>> getReports({String? status}) async {
    _ensureInitialized();
    final firestore = _firestore;

    if (firestore != null) {
      try {
        Query query = firestore
            .collection(FirebaseConstants.reportsCollection)
            .orderBy('createdAt', descending: true);
        if (status != null && status.isNotEmpty && status != 'all') {
          query = query.where('status', isEqualTo: status);
        }
        final snap = await query.get();
        return snap.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      } catch (_) {}
    }

    // Fallback to memory
    if (status != null && status.isNotEmpty && status != 'all') {
      return _memoryReports.where((r) => r.status == status).toList();
    }
    return List.from(_memoryReports);
  }

  @override
  Future<void> resolveReport(
    String reportId, {
    required String action,
    String? note,
  }) async {
    _ensureInitialized();
    final firestore = _firestore;

    // Find the report
    ReportEntity? targetReport;
    final index = _memoryReports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      targetReport = _memoryReports[index];
      final newStatus = action == 'dismiss' ? 'dismissed' : 'resolved';
      _memoryReports[index] = targetReport.copyWith(status: newStatus);
    }

    if (action == 'ban_user' && targetReport != null) {
      await updateUserStatus(
        targetReport.targetAuthorId,
        isBanned: true,
        banReason: note ?? 'Vi phạm tiêu chuẩn cộng đồng',
      );
    }

    if (firestore != null) {
      try {
        final newStatus = action == 'dismiss' ? 'dismissed' : 'resolved';
        await firestore
            .collection(FirebaseConstants.reportsCollection)
            .doc(reportId)
            .update({
              'status': newStatus,
              'resolutionAction': action,
              'resolutionNote': note ?? '',
              'resolvedAt': FieldValue.serverTimestamp(),
            });

        if (action == 'delete_content' && targetReport != null) {
          if (targetReport.targetType == ReportTargetType.post) {
            await firestore
                .collection(FirebaseConstants.postsCollection)
                .doc(targetReport.targetId)
                .delete();
          }
        }
      } catch (_) {}
    }

    await logAuditAction(
      action: 'resolve_report_$action',
      targetType: 'report',
      targetId: reportId,
      details: note ?? 'Hành động: $action',
    );
  }

  @override
  Future<List<UserEntity>> getAllUsers({String? query, String? faculty}) async {
    _ensureInitialized();
    final firestore = _firestore;

    if (firestore != null) {
      try {
        final snap = await firestore
            .collection(FirebaseConstants.usersCollection)
            .limit(50)
            .get();
        var users = snap.docs.map((d) {
          final data = d.data();
          return UserEntity(
            uid: d.id,
            email: data['email'] as String? ?? '',
            displayName: data['displayName'] as String? ?? '',
            studentId: data['studentId'] as String? ?? '',
            faculty: data['faculty'] as String? ?? '',
            major: data['major'] as String? ?? '',
            cohort: (data['cohort'] as num?)?.toInt() ?? 0,
            userType: data['userType'] as String? ?? 'student',
            isVerified: data['isVerified'] as bool? ?? false,
            isBanned: data['isBanned'] as bool? ?? false,
          );
        }).toList();

        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          users = users
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(q) ||
                    u.studentId.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q),
              )
              .toList();
        }

        if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
          users = users.where((u) => u.faculty == faculty).toList();
        }

        return users;
      } catch (_) {}
    }

    // Fallback to in-memory
    var users = List<UserEntity>.from(_memoryUsers);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      users = users
          .where(
            (u) =>
                u.displayName.toLowerCase().contains(q) ||
                u.studentId.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q),
          )
          .toList();
    }
    if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
      users = users.where((u) => u.faculty == faculty).toList();
    }
    return users;
  }

  @override
  Future<void> updateUserStatus(
    String userId, {
    required bool isBanned,
    String? banReason,
  }) async {
    _ensureInitialized();

    final idx = _memoryUsers.indexWhere(
      (u) => u.uid == userId || u.studentId == userId,
    );
    if (idx != -1) {
      _memoryUsers[idx] = _memoryUsers[idx].copyWith(isBanned: isBanned);
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update({
              'isBanned': isBanned,
              'banReason': banReason ?? '',
              'bannedAt': isBanned ? FieldValue.serverTimestamp() : null,
            });
      } catch (_) {}
    }

    await logAuditAction(
      action: isBanned ? 'ban_user' : 'unban_user',
      targetType: 'user',
      targetId: userId,
      details: banReason ?? (isBanned ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
    );
  }

  @override
  Future<void> updateUserRole(String userId, {required String newRole}) async {
    _ensureInitialized();

    final idx = _memoryUsers.indexWhere(
      (u) => u.uid == userId || u.studentId == userId,
    );
    if (idx != -1) {
      _memoryUsers[idx] = _memoryUsers[idx].copyWith(userType: newRole);
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update({
              'userType': newRole,
              'roleUpdatedAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {}
    }

    await logAuditAction(
      action: 'update_role',
      targetType: 'user',
      targetId: userId,
      details: 'Cập nhật phân quyền thành "$newRole"',
    );
  }

  @override
  Future<List<DocumentEntity>> getAllDocuments() async {
    _ensureInitialized();
    final firestore = _firestore;

    if (firestore != null) {
      try {
        final snap = await firestore
            .collection(FirebaseConstants.studyDocumentsCollection)
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((d) {
          final data = d.data();
          return DocumentEntity(
            id: d.id,
            title: data['title'] as String? ?? 'Tài liệu',
            code: data['code'] as String? ?? '',
            faculty: data['faculty'] as String? ?? '',
            fileUrl: data['fileUrl'] as String? ?? '',
            fileType: data['fileType'] as String? ?? 'pdf',
            fileSize: data['fileSize'] as String? ?? '1.0 MB',
            authorId: data['authorId'] as String? ?? '',
            authorName: data['authorName'] as String? ?? '',
            authorStudentId: data['authorStudentId'] as String? ?? '',
            downloads: (data['downloads'] as num?)?.toInt() ?? 0,
            rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
            createdAt: data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
        }).toList();
      } catch (_) {}
    }

    return List.from(_memoryDocuments);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    _ensureInitialized();
    _memoryDocuments.removeWhere((d) => d.id == documentId);

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.studyDocumentsCollection)
            .doc(documentId)
            .delete();
      } catch (_) {}
    }

    await logAuditAction(
      action: 'delete_document',
      targetType: 'document',
      targetId: documentId,
      details: 'Gỡ tài liệu học tập khỏi DocsHub',
    );
  }

  @override
  Future<void> broadcastAnnouncement({
    required String title,
    required String content,
    String? targetFaculty,
  }) async {
    final firestore = _firestore;
    final faculty = targetFaculty ?? 'Tất cả';
    final now = DateTime.now();
    final notifId = 'broadcast_${now.millisecondsSinceEpoch}';

    if (firestore != null) {
      try {
        // 1. Ghi vào collection announcements để lưu lịch sử
        await firestore.collection('announcements').add({
          'title': title,
          'content': content,
          'targetFaculty': faculty,
          'createdAt': FieldValue.serverTimestamp(),
          'sender': 'Ban Quản trị Đại học Phenikaa',
        });

        // 2. Fan-out: Lấy danh sách users và gửi in-app notification
        Query usersQuery = firestore.collection(
          FirebaseConstants.usersCollection,
        );
        if (faculty != 'Tất cả') {
          usersQuery = usersQuery.where('faculty', isEqualTo: faculty);
        }
        final usersSnap = await usersQuery.limit(200).get();

        // Batch write notification vào subcollection của từng user
        final batch = firestore.batch();
        int batchCount = 0;

        for (final userDoc in usersSnap.docs) {
          final uid = userDoc.id;
          final notifRef = firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(uid)
              .collection(FirebaseConstants.notificationsSubcollection)
              .doc('${notifId}_$uid');

          batch.set(notifRef, {
            'userId': uid,
            'title': title,
            'content': content,
            'type': 'system',
            'senderName': 'Ban Quản trị Phenikaa',
            'senderAvatar': null,
            'createdAt': Timestamp.fromDate(now),
            'isRead': false,
            'actionRoute': 'notifications',
            'extraData': {'targetFaculty': faculty},
          });

          batchCount++;
          // Firestore batch tối đa 500 operations — commit và tạo batch mới nếu cần
          if (batchCount == 490) {
            await batch.commit();
            batchCount = 0;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      } catch (_) {}
    }

    await logAuditAction(
      action: 'broadcast_announcement',
      targetType: 'announcement',
      targetId: notifId,
      details: 'Tiêu đề: "$title", Khoa mục tiêu: "$faculty"',
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.postsCollection)
            .doc(postId)
            .delete();
      } catch (_) {}
    }

    await logAuditAction(
      action: 'delete_post',
      targetType: 'post',
      targetId: postId,
      details: 'Xóa bài viết vi phạm tiêu chuẩn cộng đồng',
    );
  }

  @override
  Future<List<AdminAuditLogEntity>> getAuditLogs({int limit = 50}) async {
    _ensureInitialized();
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore
            .collection(FirebaseConstants.auditLogsCollection)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();
        return snap.docs
            .map((doc) => AdminAuditLogEntity.fromFirestore(doc))
            .toList();
      } catch (_) {}
    }

    return List.from(_memoryAuditLogs);
  }

  @override
  Future<void> logAuditAction({
    required String action,
    required String targetType,
    required String targetId,
    String? details,
  }) async {
    final currentAdmin = _auth?.currentUser;
    final adminId = currentAdmin?.uid ?? 'system_admin_uid';
    final adminEmail = currentAdmin?.email ?? 'admin@phenikaa-uni.edu.vn';

    final log = AdminAuditLogEntity(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      adminId: adminId,
      adminEmail: adminEmail,
      action: action,
      targetType: targetType,
      targetId: targetId,
      details: details ?? '',
      timestamp: DateTime.now(),
    );

    _memoryAuditLogs.insert(0, log);

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.auditLogsCollection)
            .add(log.toMap());
      } catch (_) {}
    }
  }

  @override
  Future<List<PhenikaaStudentEntity>> getPhenikaaStudents({String? query}) async {
    _ensureInitialized();
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore
            .collection(FirebaseConstants.phenikaaStudentsCollection)
            .get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((doc) => PhenikaaStudentModel.fromFirestore(doc))
              .toList();

          if (query != null && query.trim().isNotEmpty) {
            final q = query.trim().toLowerCase();
            return list.where((s) {
              return s.studentId.toLowerCase().contains(q) ||
                  s.fullName.toLowerCase().contains(q) ||
                  s.email.toLowerCase().contains(q);
            }).toList();
          }
          return list;
        }
      } catch (_) {}
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return _memoryPhenikaaStudents.where((s) {
        return s.studentId.toLowerCase().contains(q) ||
            s.fullName.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q);
      }).toList();
    }
    return List.from(_memoryPhenikaaStudents);
  }

  @override
  Future<void> addPhenikaaStudent(PhenikaaStudentEntity student) async {
    _ensureInitialized();
    final studentId = student.studentId.trim();
    final email = student.email.trim().toLowerCase();

    if (studentId.isEmpty) {
      throw Exception('Mã sinh viên không được để trống.');
    }
    if (student.fullName.trim().isEmpty) {
      throw Exception('Họ và tên sinh viên không được để trống.');
    }
    if (!FirebaseConstants.isPhenikaaEmail(email)) {
      throw Exception(
        'Email phải thuộc tên miền @st.phenikaa-uni.edu.vn hoặc @phenikaa-uni.edu.vn.',
      );
    }

    final firestore = _firestore;
    if (firestore != null) {
      // 1. Kiểm tra trùng mã sinh viên trên Firestore
      final docSnap = await firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .doc(studentId)
          .get();
      if (docSnap.exists) {
        throw Exception(
          'Mã sinh viên $studentId đã tồn tại trong danh bạ Phenikaa!',
        );
      }

      // 2. Kiểm tra trùng email trên Firestore
      final emailSnap = await firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailSnap.docs.isNotEmpty) {
        throw Exception(
          'Email $email đã được liên kết với một sinh viên khác trong danh bạ!',
        );
      }

      // 3. Lưu vào Firestore
      final data = {
        'studentId': studentId,
        'fullName': student.fullName.trim(),
        'email': email,
        'faculty': student.faculty.trim(),
        'major': student.major.trim(),
        'cohort': student.cohort,
        'isActivated': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .doc(studentId)
          .set(data);
    }

    // In-memory duplicate check & storage
    if (_memoryPhenikaaStudents.any((s) => s.studentId == studentId)) {
      throw Exception('Mã sinh viên $studentId đã tồn tại trong danh bạ!');
    }
    if (_memoryPhenikaaStudents.any((s) => s.email.toLowerCase() == email)) {
      throw Exception('Email $email đã tồn tại trong danh bạ!');
    }

    _memoryPhenikaaStudents.add(
      PhenikaaStudentModel(
        studentId: studentId,
        fullName: student.fullName.trim(),
        email: email,
        faculty: student.faculty.trim(),
        major: student.major.trim(),
        cohort: student.cohort,
        isActivated: false,
      ),
    );

    await logAuditAction(
      action: 'add_phenikaa_student',
      targetType: 'phenikaa_student',
      targetId: studentId,
      details:
          'Thêm sinh viên ${student.fullName} ($studentId) vào danh bạ kích hoạt',
    );
  }

  @override
  Future<void> updatePhenikaaStudent(PhenikaaStudentEntity student) async {
    _ensureInitialized();
    final studentId = student.studentId.trim();
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.phenikaaStudentsCollection)
            .doc(studentId)
            .update({
              'fullName': student.fullName.trim(),
              'email': student.email.trim().toLowerCase(),
              'faculty': student.faculty.trim(),
              'major': student.major.trim(),
              'cohort': student.cohort,
              'isActivated': student.isActivated,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {}
    }

    final idx = _memoryPhenikaaStudents.indexWhere(
      (s) => s.studentId == studentId,
    );
    if (idx >= 0) {
      _memoryPhenikaaStudents[idx] = student;
    }

    await logAuditAction(
      action: 'update_phenikaa_student',
      targetType: 'phenikaa_student',
      targetId: studentId,
      details:
          'Cập nhật thông tin sinh viên ${student.fullName} ($studentId)',
    );
  }

  @override
  Future<void> deletePhenikaaStudent(String studentId) async {
    _ensureInitialized();
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.phenikaaStudentsCollection)
            .doc(studentId)
            .delete();
      } catch (_) {}
    }

    _memoryPhenikaaStudents.removeWhere((s) => s.studentId == studentId);

    await logAuditAction(
      action: 'delete_phenikaa_student',
      targetType: 'phenikaa_student',
      targetId: studentId,
      details: 'Xóa sinh viên mã $studentId khỏi danh bạ Phenikaa',
    );
  }
}
