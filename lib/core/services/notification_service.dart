import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String prefPermissionRequested = 'notification_permission_requested';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String channelId = 'pu_connection_channel';
  static const String channelName = 'Thông báo PU Connection';
  static const String channelDesc = 'Kênh nhận thông báo bài viết, tin nhắn và sự kiện trường Đại học Phenikaa';

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final SharedPreferences? _prefs;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferences? prefs,
  })  : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _prefs = prefs;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
        );
        await androidImplementation.createNotificationChannel(androidChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Kiểm tra xem người dùng đã từng được hỏi cấp quyền thông báo chưa
  bool hasRequestedPermission() {
    return _prefs?.getBool(prefPermissionRequested) ?? false;
  }

  /// Kiểm tra xem thông báo có đang được bật trong cài đặt app không
  bool isNotificationsEnabled() {
    return _prefs?.getBool(prefNotificationsEnabled) ?? false;
  }

  /// Đánh dấu là đã hỏi xin quyền
  Future<void> markPermissionRequested() async {
    await _prefs?.setBool(prefPermissionRequested, true);
  }

  /// Bật/Tắt cài đặt nhận thông báo
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(prefNotificationsEnabled, enabled);
  }

  /// Yêu cầu cấp quyền thông báo từ hệ điều hành (Android 13+ / iOS)
  Future<bool> requestNotificationPermission() async {
    await markPermissionRequested();

    bool granted = false;

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? result = await androidImplementation.requestNotificationsPermission();
        granted = result ?? false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final bool? result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = result ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }

    await setNotificationsEnabled(granted);

    if (granted) {
      // Gửi thông báo chào mừng khi cấp quyền thành công
      await showWelcomeNotification();
    }

    return granted;
  }

  /// Gửi thông báo cục bộ thực tế
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Thông báo chào mừng sinh viên khi cấp quyền thông báo lần đầu
  Future<void> showWelcomeNotification() async {
    await showNotification(
      id: 1001,
      title: 'Chào mừng bạn đến với PU Connection! 🎉',
      body: 'Thông báo đã được bật. Bạn sẽ nhận được tin nhắn và tin tức mới nhất từ trường Phenikaa!',
      payload: 'welcome',
    );
  }

  /// Gửi thông báo thử nghiệm từ phần Cài đặt
  Future<void> sendTestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Phenikaa University Connection 🔔',
      body: 'Đây là thông báo thử nghiệm thực tế. Hệ thống thông báo hoạt động bình thường!',
      payload: 'test_notification',
    );
  }
}
