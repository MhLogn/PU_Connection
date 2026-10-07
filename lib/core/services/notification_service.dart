import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';

/// Top-level background message handler cho Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('FCM Remote Message in background: ${message.messageId} - ${message.notification?.title}');
}

class NotificationService {
  static const String prefPermissionRequested = 'notification_permission_requested';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String channelId = 'pu_connection_channel';
  static const String channelName = 'Thông báo PU Connection';
  static const String channelDesc = 'Kênh nhận thông báo bài viết, tin nhắn và sự kiện trường Đại học Phenikaa';

  // Topic FCM Constants
  static const String topicCampusNews = 'phenikaa_campus_news';
  static const String topicEvents = 'phenikaa_events';

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final SharedPreferences? _prefs;
  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferences? prefs,
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _prefs = prefs,
        _messaging = messaging,
        _firestore = firestore;

  bool _isInitialized = false;
  String? _cachedFcmToken;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;
  FirebaseMessaging? get _fcmInstance {
    if (_messaging != null) return _messaging;
    if (_hasFirebase) {
      try {
        return FirebaseMessaging.instance;
      } catch (_) {}
    }
    return null;
  }

  FirebaseFirestore? get _firestoreInstance {
    if (_firestore != null) return _firestore;
    if (_hasFirebase) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

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

      // Initialize FCM listeners if Firebase is available
      await _initFcm();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Khởi tạo các listener FCM
  Future<void> _initFcm() async {
    final fcm = _fcmInstance;
    if (fcm == null) return;

    try {
      // Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');

        // Chỉ hiển thị banner nếu người dùng đã bật thông báo trong cài đặt
        if (!isNotificationsEnabled()) return;

        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'PU Connection';
        final body = notification?.body ?? message.data['body'] ?? '';

        showNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: message.data['route'] ?? message.data['payload'],
        );
      });

      // Lắng nghe khi người dùng bấm vào thông báo từ background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM message opened from background: ${message.data}');
      });

      // Kiểm tra xem ứng dụng có được mở từ trạng thái terminated do bấm thông báo không
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM initial message on app launch: ${initialMessage.data}');
      }

      // Lắng nghe token refresh và đồng bộ
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = fcm.onTokenRefresh.listen((newToken) {
        _cachedFcmToken = newToken;
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          syncUserFcmToken(_currentUserId!);
        }
      });
    } catch (e) {
      debugPrint('Error setting up FCM listeners: $e');
    }
  }

  /// Lấy FCM Device Token hiện tại
  Future<String?> getFcmToken() async {
    if (_cachedFcmToken != null) return _cachedFcmToken;
    final fcm = _fcmInstance;
    if (fcm == null) return null;

    try {
      _cachedFcmToken = await fcm.getToken();
      return _cachedFcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Đồng bộ hóa FCM token của người dùng lên Firestore users/{uid}
  Future<void> syncUserFcmToken(String uid) async {
    if (uid.isEmpty) return;
    _currentUserId = uid;

    final token = await getFcmToken();
    if (token == null || token.isEmpty) return;

    final firestore = _firestoreInstance;
    if (firestore == null) return;

    try {
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Đăng ký mặc định các topics trường học
      await subscribeToTopic(topicCampusNews);
      await subscribeToTopic(topicEvents);
      debugPrint('FCM token synchronized for user $uid');
    } catch (e) {
      debugPrint('Error syncing user FCM token: $e');
    }
  }

  /// Xóa token của thiết bị khỏi Firestore khi đăng xuất (để không nhận thông báo nhầm)
  Future<void> clearUserFcmToken(String uid) async {
    if (uid.isEmpty) return;
    final firestore = _firestoreInstance;
    final token = _cachedFcmToken ?? await getFcmToken();

    try {
      if (firestore != null && token != null) {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .update({
          'fcmToken': FieldValue.delete(),
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('Error clearing user FCM token: $e');
    } finally {
      _currentUserId = null;
    }
  }

  /// Đăng ký nhận thông báo theo Topic
  Future<void> subscribeToTopic(String topic) async {
    final fcm = _fcmInstance;
    if (fcm == null) return;
    try {
      await fcm.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Hủy đăng ký nhận thông báo theo Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    final fcm = _fcmInstance;
    if (fcm == null) return;
    try {
      await fcm.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
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

  /// Yêu cầu cấp quyền thông báo từ hệ điều hành (Android 13+ / iOS & FCM)
  Future<bool> requestNotificationPermission() async {
    await markPermissionRequested();

    bool granted = false;

    // Yêu cầu quyền FCM
    final fcm = _fcmInstance;
    if (fcm != null) {
      try {
        final settings = await fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } catch (e) {
        debugPrint('Error requesting FCM permission: $e');
      }
    }

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? result = await androidImplementation.requestNotificationsPermission();
        granted = result ?? granted;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final bool? result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = result ?? granted;
      }
    } catch (e) {
      debugPrint('Error requesting local notification permission: $e');
    }

    await setNotificationsEnabled(granted);

    if (granted) {
      // Gửi thông báo chào mừng khi cấp quyền thành công
      await showWelcomeNotification();

      // Nếu người dùng đã đăng nhập, đồng bộ token
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await syncUserFcmToken(_currentUserId!);
      }
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
    final token = await getFcmToken();
    final tokenShort = (token != null && token.length > 12)
        ? '${token.substring(0, 6)}...${token.substring(token.length - 6)}'
        : (token ?? 'Chưa khả dụng');

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Phenikaa University Connection 🔔',
      body: 'Thông báo hoạt động bình thường! FCM Token: $tokenShort',
      payload: 'test_notification',
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
