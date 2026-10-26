import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class NovaFirebaseRuntime {
  NovaFirebaseRuntime._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool initialized = false;
  static bool appCheckActivated = false;
  static String? initializationError;

  static bool get configured =>
      apiKey.isNotEmpty && appId.isNotEmpty &&
      messagingSenderId.isNotEmpty && projectId.isNotEmpty;

  static Future<void> initialize() async {
    if (!configured) {
      initializationError = 'إعدادات Firebase غير مضافة للبناء الحالي.';
      return;
    }
    try {
      await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      ));
      initialized = true;
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        );
        appCheckActivated = true;
      } catch (error) {
        initializationError = 'Firebase جاهز، لكن تعذر تفعيل App Check: $error';
      }
    } catch (error) {
      initializationError = 'تعذر تهيئة Firebase: $error';
    }
  }
}
