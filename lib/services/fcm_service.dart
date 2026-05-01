import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'token_manager.dart';

/// ─────────────────────────────────────────────────────────────
/// FCM Service — Handles Firebase Cloud Messaging for push
/// notifications. Manages token lifecycle, foreground display
/// via local notifications, and background message handling.
/// ─────────────────────────────────────────────────────────────

/// Top-level function required by Firebase for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 [FCM] Background message: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Android notification channel for order updates
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'govardhan_orders',
    'Order Updates',
    description: 'Notifications for order status changes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM — call once after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        '📱 [FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('📱 [FCM] Notifications denied by user');
      return;
    }

    // 2. Setup local notifications for foreground display
    await _setupLocalNotifications();

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // 4. Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification taps (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Check if app was opened from a terminated state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Get and save FCM token
    await _saveToken();

    // 8. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('📱 [FCM] Token refreshed');
      await _sendTokenToServer(newToken);
    });
  }

  /// Setup flutter_local_notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    // Android setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(
            '📱 [FCM] Local notification tapped: ${details.payload}');
        // Handle navigation based on payload if needed
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_orderChannel);
    }
  }

  /// Handle foreground messages — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint(
        '📱 [FCM] Foreground: ${notification.title} — ${notification.body}');

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannel.id,
          _orderChannel.name,
          channelDescription: _orderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF6A00),
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap — navigate to relevant screen
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
        '📱 [FCM] Notification tapped: ${message.data}');
    // Future: implement deep linking based on message.data['type']
    // e.g., navigate to order tracking screen
  }

  /// Get and save the FCM token to server
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint(
            '📱 [FCM] Token: ${token.substring(0, 20)}...');
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('📱 [FCM] Error getting token: $e');
    }
  }

  /// Send FCM token to backend API
  Future<void> _sendTokenToServer(String token) async {
    try {
      final accessToken = await TokenManager.getAccessToken();
      if (accessToken == null) return;

      await http.post(
        Uri.parse('${ApiService.baseUrl}/profile/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
      debugPrint('📱 [FCM] Token sent to server');
    } catch (e) {
      debugPrint('📱 [FCM] Failed to send token: $e');
    }
  }

  /// Remove FCM token from server (call on logout)
  Future<void> removeTokenFromServer() async {
    try {
      final accessToken = await TokenManager.getAccessToken();
      if (accessToken == null) return;

      await http.delete(
        Uri.parse('${ApiService.baseUrl}/profile/fcm-token'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      debugPrint('📱 [FCM] Token removed from server');
    } catch (e) {
      debugPrint('📱 [FCM] Failed to remove token: $e');
    }
  }
}
