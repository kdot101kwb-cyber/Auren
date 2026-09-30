import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AurenFcmService {
  AurenFcmService._();
  static final instance = AurenFcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(RemoteMessage message)? _openHandler;
  RemoteMessage? _pendingOpenMessage;

  void setOpenHandler(void Function(RemoteMessage message) handler) {
    _openHandler = handler;
    final pending = _pendingOpenMessage;
    if (pending != null) {
      _pendingOpenMessage = null;
      Future<void>.microtask(() => handler(pending));
    }
  }

  void _handleOpen(RemoteMessage message) {
    final handler = _openHandler;
    if (handler != null) {
      handler(message);
    } else {
      _pendingOpenMessage = message;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);

    const channel = AndroidNotificationChannel(
      'auren_sports_alerts',
      'AUREN Sports Alerts',
      description: 'Live match alerts from AUREN.',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(const Duration(milliseconds: 700), () => _handleOpen(initialMessage));
    }
    _messaging.onTokenRefresh.listen(_saveToken);

    await _registerCurrentToken();
    FirebaseAuth.instance.authStateChanges().listen((_) => _registerCurrentToken());
  }

  Future<void> _registerCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.isEmpty) return;
    final id = sha256.convert(utf8.encode(token)).toString().substring(0, 40);
    await _db.collection('users').doc(user.uid).collection('fcmTokens').doc(id).set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
      'enabled': true,
    }, SetOptions(merge: true));
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      notification.hashCode,
      notification.title ?? 'AUREN',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auren_sports_alerts',
          'AUREN Sports Alerts',
          channelDescription: 'Live match alerts from AUREN.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
