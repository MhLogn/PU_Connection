import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/notifications/domain/entities/notification_type.dart';
import 'package:pu_connection/features/notifications/domain/entities/notification_entity.dart';
import 'package:pu_connection/features/notifications/data/models/notification_model.dart';
import 'package:pu_connection/features/notifications/data/repositories/in_app_notification_repository_impl.dart';
import 'package:pu_connection/features/notifications/presentation/cubit/in_app_notifications_cubit.dart';
import 'package:pu_connection/features/notifications/presentation/cubit/in_app_notifications_state.dart';

void main() {
  group('NotificationType Tests', () {
    test('displayName returns Vietnamese label for each type', () {
      expect(NotificationType.academic.displayName, 'Học tập');
      expect(NotificationType.social.displayName, 'Bạn bè & Tương tác');
      expect(NotificationType.event.displayName, 'Sự kiện & CLB');
      expect(NotificationType.system.displayName, 'Hệ thống');
    });

    test('fromString parses common strings correctly', () {
      expect(
        NotificationType.fromString('academic'),
        NotificationType.academic,
      );
      expect(NotificationType.fromString('study'), NotificationType.academic);
      expect(NotificationType.fromString('social'), NotificationType.social);
      expect(NotificationType.fromString('friend'), NotificationType.social);
      expect(NotificationType.fromString('event'), NotificationType.event);
      expect(NotificationType.fromString('club'), NotificationType.event);
      expect(NotificationType.fromString('system'), NotificationType.system);
      expect(NotificationType.fromString(null), NotificationType.system);
      expect(NotificationType.fromString('unknown'), NotificationType.system);
    });
  });

  group('NotificationModel Tests', () {
    test('toMap and fromMap serialization round-trip', () {
      final now = DateTime(2026, 10, 11, 14, 30);
      final model = NotificationModel(
        id: 'notif_1',
        userId: 'user_abc',
        title: 'Đăng ký tín chỉ HK2',
        content: 'Cổng đăng ký mở từ ngày 15/10',
        type: NotificationType.academic,
        senderName: 'Phòng Đào tạo',
        senderAvatar: 'https://example.com/avatar.png',
        createdAt: now,
        isRead: false,
        actionRoute: 'academic_schedule',
        extraData: {'priority': 'high'},
      );

      final map = model.toMap();
      expect(map['userId'], 'user_abc');
      expect(map['title'], 'Đăng ký tín chỉ HK2');
      expect(map['type'], 'academic');
      expect(map['senderName'], 'Phòng Đào tạo');
      expect(map['isRead'], false);
      expect(map['actionRoute'], 'academic_schedule');
      expect(map['extraData'], {'priority': 'high'});

      final deserialized = NotificationModel.fromMap(map, 'notif_1');
      expect(deserialized.id, 'notif_1');
      expect(deserialized.userId, 'user_abc');
      expect(deserialized.type, NotificationType.academic);
      expect(deserialized.senderAvatar, 'https://example.com/avatar.png');
      expect(deserialized.actionRoute, 'academic_schedule');
    });

    test('fromEntity creates model from entity correctly', () {
      final entity = NotificationEntity(
        id: 'notif_2',
        userId: 'user_xyz',
        title: 'Lời mời kết bạn',
        content: 'Nguyễn Văn A muốn kết bạn',
        type: NotificationType.social,
        senderName: 'Nguyễn Văn A',
        createdAt: DateTime(2026, 10, 10),
        isRead: true,
      );

      final model = NotificationModel.fromEntity(entity);
      expect(model.id, 'notif_2');
      expect(model.type, NotificationType.social);
      expect(model.isRead, true);
      expect(model.senderAvatar, isNull);
    });

    test('fromMap parses both content and body schemas with fallback [NOTIF-002]', () {
      // 1. Map with only body (legacy / club notifications)
      final mapWithBody = {
        'userId': 'user_1',
        'title': 'CLB được duyệt',
        'body': 'Đề xuất thành lập CLB của bạn đã được duyệt.',
        'type': 'club_approved',
      };
      final notifFromBody = NotificationModel.fromMap(mapWithBody, 'doc_body');
      expect(notifFromBody.content, 'Đề xuất thành lập CLB của bạn đã được duyệt.');

      // 2. Map with only content
      final mapWithContent = {
        'userId': 'user_2',
        'title': 'Thông báo hệ thống',
        'content': 'Hệ thống bảo trì vào lúc 23h.',
        'type': 'system',
      };
      final notifFromContent = NotificationModel.fromMap(mapWithContent, 'doc_content');
      expect(notifFromContent.content, 'Hệ thống bảo trì vào lúc 23h.');

      // 3. Map with both: content takes precedence if not empty
      final mapWithBoth = {
        'userId': 'user_3',
        'title': 'Tiêu đề',
        'content': 'Nội dung chính',
        'body': 'Nội dung phụ',
        'type': 'system',
      };
      final notifFromBoth = NotificationModel.fromMap(mapWithBoth, 'doc_both');
      expect(notifFromBoth.content, 'Nội dung chính');
    });
  });

  group('NotificationEntity Tests', () {
    test('copyWith updates specified fields', () {
      final original = NotificationEntity(
        id: 'n1',
        userId: 'u1',
        title: 'Original Title',
        content: 'Content',
        type: NotificationType.event,
        senderName: 'CLB IT',
        createdAt: DateTime(2026, 10, 1),
        isRead: false,
      );

      final updated = original.copyWith(isRead: true, title: 'Updated Title');
      expect(updated.isRead, true);
      expect(updated.title, 'Updated Title');
      expect(updated.id, 'n1'); // unchanged
      expect(updated.type, NotificationType.event); // unchanged
    });
  });

  group('InAppNotificationsState Tests', () {
    test('initial state has correct defaults', () {
      const state = InAppNotificationsState();
      expect(state.status, NotificationsStatus.initial);
      expect(state.notifications, isEmpty);
      expect(state.selectedFilter, isNull);
      expect(state.unreadCount, 0);
    });

    test('filteredNotifications returns all when no filter selected', () {
      final state = InAppNotificationsState(
        notifications: [
          NotificationEntity(
            id: '1',
            userId: 'u',
            title: 'A',
            content: 'a',
            type: NotificationType.academic,
            senderName: 'S',
            createdAt: DateTime.now(),
          ),
          NotificationEntity(
            id: '2',
            userId: 'u',
            title: 'B',
            content: 'b',
            type: NotificationType.social,
            senderName: 'S',
            createdAt: DateTime.now(),
          ),
        ],
      );
      expect(state.filteredNotifications.length, 2);
    });

    test('filteredNotifications filters by selected type', () {
      final state = InAppNotificationsState(
        selectedFilter: NotificationType.academic,
        notifications: [
          NotificationEntity(
            id: '1',
            userId: 'u',
            title: 'A',
            content: 'a',
            type: NotificationType.academic,
            senderName: 'S',
            createdAt: DateTime.now(),
          ),
          NotificationEntity(
            id: '2',
            userId: 'u',
            title: 'B',
            content: 'b',
            type: NotificationType.social,
            senderName: 'S',
            createdAt: DateTime.now(),
          ),
        ],
      );
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.type, NotificationType.academic);
    });

    test('unreadCount returns correct number', () {
      final state = InAppNotificationsState(
        notifications: [
          NotificationEntity(
            id: '1',
            userId: 'u',
            title: 'A',
            content: 'a',
            type: NotificationType.academic,
            senderName: 'S',
            createdAt: DateTime.now(),
            isRead: false,
          ),
          NotificationEntity(
            id: '2',
            userId: 'u',
            title: 'B',
            content: 'b',
            type: NotificationType.social,
            senderName: 'S',
            createdAt: DateTime.now(),
            isRead: true,
          ),
          NotificationEntity(
            id: '3',
            userId: 'u',
            title: 'C',
            content: 'c',
            type: NotificationType.event,
            senderName: 'S',
            createdAt: DateTime.now(),
            isRead: false,
          ),
        ],
      );
      expect(state.unreadCount, 2);
    });
  });

  group('InAppNotificationRepositoryImpl Tests', () {
    late InAppNotificationRepositoryImpl repository;

    setUp(() {
      InAppNotificationRepositoryImpl.enableSeedNotifications = true;
      repository = InAppNotificationRepositoryImpl(); // in-memory mode
    });

    tearDown(() {
      InAppNotificationRepositoryImpl.enableSeedNotifications = false;
    });

    test('watchNotifications emits seed notifications initially', () async {
      final stream = repository.watchNotifications('test_user');
      final first = await stream.first;
      expect(first, isNotEmpty);
      expect(first.every((n) => n.userId == 'test_user'), isTrue);
    });

    test('markAsRead updates notification in memory', () async {
      // Get initial list
      final list = await repository.getNotifications('test_user');
      expect(list, isNotEmpty);
      final firstNotif = list.first;
      expect(firstNotif.isRead, isFalse);

      await repository.markAsRead('test_user', firstNotif.id);

      final updated = await repository.getNotifications('test_user');
      final found = updated.firstWhere((n) => n.id == firstNotif.id);
      expect(found.isRead, isTrue);
    });

    test('markAllAsRead marks all notifications as read', () async {
      await repository.getNotifications('test_user'); // init seed
      await repository.markAllAsRead('test_user');

      final updated = await repository.getNotifications('test_user');
      expect(updated.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes notification from list', () async {
      final list = await repository.getNotifications('test_user');
      final count = list.length;
      final target = list.first;

      await repository.deleteNotification('test_user', target.id);

      final updated = await repository.getNotifications('test_user');
      expect(updated.length, count - 1);
      expect(updated.any((n) => n.id == target.id), isFalse);
    });

    test('sendNotification adds notification to user list', () async {
      final notif = NotificationEntity(
        id: 'custom_notif',
        userId: 'test_user',
        title: 'Custom Test',
        content: 'Test content',
        type: NotificationType.system,
        senderName: 'Test System',
        createdAt: DateTime.now(),
      );

      await repository.sendNotification(notif);

      final list = await repository.getNotifications('test_user');
      expect(list.any((n) => n.id == 'custom_notif'), isTrue);
    });
  });

  group('InAppNotificationsCubit Tests', () {
    late InAppNotificationRepositoryImpl repository;
    late InAppNotificationsCubit cubit;

    setUp(() {
      InAppNotificationRepositoryImpl.enableSeedNotifications = true;
      repository = InAppNotificationRepositoryImpl();
      cubit = InAppNotificationsCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
      InAppNotificationRepositoryImpl.enableSeedNotifications = false;
    });

    test('initial state is NotificationsStatus.initial', () {
      expect(cubit.state.status, NotificationsStatus.initial);
      expect(cubit.state.notifications, isEmpty);
    });

    test('init loads notifications and sets status to loaded', () async {
      cubit.init('cubit_test_user');

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.notifications, isNotEmpty);
      expect(cubit.currentUserId, 'cubit_test_user');
    });

    test('setFilter changes selectedFilter in state', () async {
      cubit.init('cubit_filter_user');
      await Future.delayed(const Duration(milliseconds: 100));

      cubit.setFilter(NotificationType.academic);
      expect(cubit.state.selectedFilter, NotificationType.academic);

      cubit.setFilter(null);
      expect(cubit.state.selectedFilter, isNull);
    });

    test('markAllAsRead sets success message', () async {
      cubit.init('cubit_read_user');
      await Future.delayed(const Duration(milliseconds: 100));

      await cubit.markAllAsRead();
      expect(cubit.state.successMessage, isNotNull);
    });

    test('deleteNotification removes notification', () async {
      cubit.init('cubit_delete_user');
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = cubit.state.notifications.length;
      final targetId = cubit.state.notifications.first.id;

      await cubit.deleteNotification(targetId);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.notifications.length, lessThan(initialCount));
    });
  });
}
