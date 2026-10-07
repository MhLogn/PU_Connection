import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_connection/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    late SharedPreferences prefs;
    late NotificationService notificationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notificationService = NotificationService(prefs: prefs);
    });

    test('Initial state: hasRequestedPermission is false', () {
      expect(notificationService.hasRequestedPermission(), false);
      expect(notificationService.isNotificationsEnabled(), false);
    });

    test('markPermissionRequested sets flag to true', () async {
      await notificationService.markPermissionRequested();
      expect(notificationService.hasRequestedPermission(), true);
      expect(prefs.getBool(NotificationService.prefPermissionRequested), true);
    });

    test('setNotificationsEnabled sets preference correctly', () async {
      await notificationService.setNotificationsEnabled(true);
      expect(notificationService.isNotificationsEnabled(), true);
      expect(prefs.getBool(NotificationService.prefNotificationsEnabled), true);

      await notificationService.setNotificationsEnabled(false);
      expect(notificationService.isNotificationsEnabled(), false);
      expect(prefs.getBool(NotificationService.prefNotificationsEnabled), false);
    });

    test('Channel constants are configured correctly', () {
      expect(NotificationService.channelId, 'pu_connection_channel');
      expect(NotificationService.channelName, 'Thông báo PU Connection');
      expect(NotificationService.channelDesc.contains('Phenikaa'), true);
    });

    test('FCM Topic constants are configured correctly', () {
      expect(NotificationService.topicCampusNews, 'phenikaa_campus_news');
      expect(NotificationService.topicEvents, 'phenikaa_events');
    });

    test('getFcmToken returns null gracefully when Firebase is not initialized in test', () async {
      final token = await notificationService.getFcmToken();
      expect(token, isNull);
    });

    test('syncUserFcmToken and clearUserFcmToken handle empty or uninitialized safely', () async {
      await notificationService.syncUserFcmToken('');
      await notificationService.clearUserFcmToken('');
      expect(true, isTrue);
    });
  });
}
