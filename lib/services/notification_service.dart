import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  debugPrint(' [FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId   = 'fixit_channel';
  static const String _channelName = 'FixIT Service';
  static const String _channelDesc = 'Notifikasi booking dan pengumuman';

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(' [FCM Foreground] ${message.notification?.title}');
      final notif = message.notification;
      if (notif != null) {
        showNotification(title: notif.title ?? '', body: notif.body ?? '');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(' [FCM OpenedApp] ${message.data}');

    });

    _initialized = true;
    debugPrint(' NotificationService initialized (FCM + Local)');
  }

  Future<void> requestPermission() async {

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }


  Future<String?> getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('🔑 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Gagal ambil FCM token: $e');
      return null;
    }
  }

  Future<void> saveFcmTokenToServer(String email) async {
    try {
      final token = await getFcmToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(
          'http://${ApiService.ipAddress}/fixit_api/save_fcm_token.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'fcm_token': token}),
      );
      debugPrint('📡 Save FCM token: ${response.body}');

      // Refresh token secara otomatis jika berubah
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM Token refresh');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'fcm_token': newToken}),
        );
      });
    } catch (e) {
      debugPrint('❌ Gagal simpan FCM token: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

 
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notifikasi di-tap: ${response.payload}');
  }
}
