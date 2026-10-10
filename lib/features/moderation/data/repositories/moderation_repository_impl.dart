import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/blocked_user_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../models/blocked_user_model.dart';
import '../models/report_model.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final FirebaseFirestore? _customFirestore;

  ModerationRepositoryImpl({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  // --- In-memory fallback for offline & unit tests ---
  static final List<ReportEntity> _memoryReports = [];
  static final Map<String, List<BlockedUserEntity>> _memoryBlockedUsers = {};
  static final StreamController<void> _notifier = StreamController<void>.broadcast();

  static void resetMemory() {
    _memoryReports.clear();
    _memoryBlockedUsers.clear();
  }

  @override
  Future<void> submitReport(ReportEntity report) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final model = ReportModel(
          id: report.id,
          reporterId: report.reporterId,
          reporterName: report.reporterName,
          targetId: report.targetId,
          targetType: report.targetType,
          targetAuthorId: report.targetAuthorId,
          targetAuthorName: report.targetAuthorName,
          reason: report.reason,
          details: report.details,
          status: report.status,
          createdAt: report.createdAt,
        );

        await firestore
            .collection(FirebaseConstants.reportsCollection)
            .doc(report.id.isNotEmpty ? report.id : null)
            .set(model.toMap());
        return;
      } catch (_) {}
    }

    _memoryReports.add(report);
    _notifier.add(null);
  }

  @override
  Future<void> blockUser({
    required String currentUserId,
    required BlockedUserEntity blockedUser,
  }) async {
    if (currentUserId.isEmpty || blockedUser.userId.isEmpty || currentUserId == blockedUser.userId) {
      return;
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final model = BlockedUserModel(
          userId: blockedUser.userId,
          userName: blockedUser.userName,
          userAvatar: blockedUser.userAvatar,
          userFaculty: blockedUser.userFaculty,
          blockedAt: blockedUser.blockedAt ?? DateTime.now(),
        );

        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.blockedUsersSubcollection)
            .doc(blockedUser.userId)
            .set(model.toMap());
        return;
      } catch (_) {}
    }

    final list = _memoryBlockedUsers.putIfAbsent(currentUserId, () => []);
    list.removeWhere((u) => u.userId == blockedUser.userId);
    list.add(blockedUser);
    _notifier.add(null);
  }

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (currentUserId.isEmpty || blockedUserId.isEmpty) return;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.blockedUsersSubcollection)
            .doc(blockedUserId)
            .delete();
        return;
      } catch (_) {}
    }

    _memoryBlockedUsers[currentUserId]?.removeWhere((u) => u.userId == blockedUserId);
    _notifier.add(null);
  }

  @override
  Stream<List<BlockedUserEntity>> getBlockedUsersStream(String currentUserId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emitList() {
          final list = _memoryBlockedUsers[currentUserId] ?? [];
          controller.add(List<BlockedUserEntity>.from(list));
        }

        emitList();
        final sub = _notifier.stream.listen((_) => emitList());
        controller.onCancel = () => sub.cancel();
      });
    }

    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(currentUserId)
        .collection(FirebaseConstants.blockedUsersSubcollection)
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BlockedUserModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    if (currentUserId.isEmpty) return [];

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(currentUserId)
            .collection(FirebaseConstants.blockedUsersSubcollection)
            .get();
        return snap.docs.map((d) => d.id).toList();
      } catch (_) {}
    }

    return (_memoryBlockedUsers[currentUserId] ?? []).map((u) => u.userId).toList();
  }
}
