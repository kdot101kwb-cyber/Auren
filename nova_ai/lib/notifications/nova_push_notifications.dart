import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_runtime.dart';

class NovaPushNotifications {
  NovaPushNotifications._();

  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;

  static Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }

      await _tokenSubscription?.cancel();
      _tokenSubscription = messaging.onTokenRefresh.listen((freshToken) {
        unawaited(_registerToken(freshToken));
      });

      await _messageSubscription?.cancel();
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        final status = message.data['status'] ?? '';
        final completed = status == 'succeeded' || status == 'completed';
        final title = message.notification?.title ?? 'NOVA';
        final body = message.notification?.body ?? 'لديك تحديث جديد في مركز مهام NOVA.';
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: completed ? Colors.green.shade700 : Colors.deepOrange.shade800,
              behavior: SnackBarBehavior.floating,
              content: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    completed ? Icons.check_circle : Icons.notifications_active,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$title\n$body',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 7),
            ),
          );
      });
    } catch (_) {
      // Push setup is optional; it must never prevent NOVA from opening.
    }
  }

  static Future<void> _registerToken(String token) async {
    await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('registerNovaDeviceToken')
        .call(<String, dynamic>{
      'token': token,
      'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    });
  }
}
