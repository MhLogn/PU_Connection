import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/in_app_notification_repository.dart';
import '../models/notification_model.dart';

class InAppNotificationRepositoryImpl implements InAppNotificationRepository {
  final FirebaseFirestore? _firestore;

  // In-memory cache & fallback phục vụ test / offline
  final Map<String, List<NotificationEntity>> _inMemoryStore = {};
  final Map<String, StreamController<List<NotificationEntity>>> _controllers =
      {};

  InAppNotificationRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamController<List<NotificationEntity>> _getController(String userId) {
    if (!_controllers.containsKey(userId) || _controllers[userId]!.isClosed) {
      _controllers[userId] =
          StreamController<List<NotificationEntity>>.broadcast();
    }
    return _controllers[userId]!;
  }

  static bool enableSeedNotifications = false;

  List<NotificationEntity> _getInitialSeed(String userId) {
    if (!enableSeedNotifications) return [];
    final now = DateTime.now();
    return [
      NotificationEntity(
        id: 'seed_notif_1',
        userId: userId,
        senderName: 'Phòng Đào tạo Phenikaa',
        title: 'Đăng ký học phần HK2 (2025-2026)',
        content:
            'Hệ thống mở cổng đăng ký tín chỉ đợt 1 cho sinh viên K16, K17. Sinh viên lưu ý kiểm tra điều kiện tiên quyết và thời gian đóng học phí.',
        type: NotificationType.academic,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
        actionRoute: 'academic_schedule',
      ),
      NotificationEntity(
        id: 'seed_notif_2',
        userId: userId,
        senderName: 'Phòng Công tác Sinh viên',
        title: 'Xét Học bổng Khuyến khích Học tập Kỳ 1',
        content:
            'Công bố danh sách dự kiến sinh viên đạt học bổng Xuất sắc và Giỏi. Thời gian tiếp nhận phản hồi đến hết ngày 18/10.',
        type: NotificationType.academic,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationEntity(
        id: 'seed_notif_3',
        userId: userId,
        senderName: 'Đoàn Thanh Niên & CLB Thể Thao',
        title: 'Khai mạc Hội thao Phenikaa Youth Games 2026',
        content:
            'Hội thao toàn trường với 6 môn thi đấu chính thức (Bóng đá, Cầu lông, Bóng bàn, Cờ vua...). Đăng ký ngay tại Nhà thi đấu Đa năng.',
        type: NotificationType.event,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionRoute: 'events',
      ),
      NotificationEntity(
        id: 'seed_notif_4',
        userId: userId,
        senderName: 'PU Connection Security',
        title: 'Bảo vệ an toàn tài khoản sinh viên',
        content:
            'Khuyến nghị cập nhật mật khẩu định kỳ và không chia sẻ mã sinh viên, mật khẩu cổng đào tạo với bất kỳ ai.',
        type: NotificationType.system,
        createdAt: now.subtract(const Duration(days: 4)),
        isRead: true,
      ),
    ];
  }

  void _notify(String userId) {
    final list = _inMemoryStore[userId] ?? [];
    // Sắp xếp mới nhất lên đầu
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _getController(userId).add(List.unmodifiable(list));
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    // Khởi tạo seed nếu chưa có trong memory
    if (!_inMemoryStore.containsKey(userId)) {
      _inMemoryStore[userId] = _getInitialSeed(userId);
    }

    final db = _db;
    if (db == null) {
      Timer.run(() => _notify(userId));
      return _getController(userId).stream;
    }

    // Kết nối real-time Firestore
    try {
      final notifCol = db
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.notificationsSubcollection);

      return notifCol
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              // Nếu Firestore chưa có doc nào, hiển thị danh sách seed
              final initial = _inMemoryStore[userId] ?? _getInitialSeed(userId);
              _inMemoryStore[userId] = initial;
              return initial;
            }

            final firestoreList = snapshot.docs
                .map((doc) => NotificationModel.fromSnapshot(doc))
                .toList();

            _inMemoryStore[userId] = firestoreList;
            return firestoreList;
          })
          .handleError((_) {
            // Fallback gracefully khi offline hoặc permissions
            return _inMemoryStore[userId] ?? _getInitialSeed(userId);
          });
    } catch (_) {
      Timer.run(() => _notify(userId));
      return _getController(userId).stream;
    }
  }

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    if (userId.isEmpty) return [];

    final db = _db;
    if (db != null) {
      try {
        final query = await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.notificationsSubcollection)
            .orderBy('createdAt', descending: true)
            .get();

        if (query.docs.isNotEmpty) {
          final list = query.docs
              .map((doc) => NotificationModel.fromSnapshot(doc))
              .toList();
          _inMemoryStore[userId] = list;
          return list;
        }
      } catch (_) {}
    }

    return _inMemoryStore[userId] ??= _getInitialSeed(userId);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    // 1. Cập nhật In-memory
    final list = _inMemoryStore[userId];
    if (list != null) {
      final index = list.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        list[index] = list[index].copyWith(isRead: true);
        _notify(userId);
      }
    }

    // 2. Cập nhật Firestore
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.notificationsSubcollection)
            .doc(notificationId)
            .update({'isRead': true});
      } catch (_) {}
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    // 1. Cập nhật In-memory
    final list = _inMemoryStore[userId];
    if (list != null) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isRead: true);
      }
      _notify(userId);
    }

    // 2. Cập nhật Firestore batch
    final db = _db;
    if (db != null) {
      try {
        final unreadQuery = await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.notificationsSubcollection)
            .where('isRead', isEqualTo: false)
            .get();

        final batch = db.batch();
        for (final doc in unreadQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    // 1. Cập nhật In-memory
    final list = _inMemoryStore[userId];
    if (list != null) {
      list.removeWhere((n) => n.id == notificationId);
      _notify(userId);
    }

    // 2. Cập nhật Firestore
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.notificationsSubcollection)
            .doc(notificationId)
            .delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> sendNotification(NotificationEntity notification) async {
    final userId = notification.userId;
    if (userId.isEmpty) return;

    // 1. Lưu In-memory
    final list = _inMemoryStore.putIfAbsent(
      userId,
      () => _getInitialSeed(userId),
    );
    list.removeWhere((n) => n.id == notification.id);
    list.insert(0, notification);
    _notify(userId);

    // 2. Ghi lên Firestore
    final db = _db;
    if (db != null) {
      try {
        final model = NotificationModel.fromEntity(notification);
        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.notificationsSubcollection)
            .doc(notification.id)
            .set(model.toMap());
      } catch (_) {}
    }
  }
}
