import 'package:firebase_core/firebase_core.dart';

/// Temporary demo configuration.
/// This is deliberately not a real Firebase credential set.
/// Production builds must replace this file using FlutterFire CLI.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'DEMO_API_KEY',
        appId: '1:000000000000:android:demo00000000000000',
        messagingSenderId: '000000000000',
        projectId: 'auren-90ccc',
        storageBucket: 'auren-90ccc.firebasestorage.app',
      );
}
