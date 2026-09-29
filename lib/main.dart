@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/shell/presentation/auren_shell.dart';
import 'features/tv/presentation/auren_tv_screen.dart';
import 'services/tv/auren_tv_watch_together_service.dart';
import 'services/offline/auren_offline_sync_service.dart';

final GlobalKey<NavigatorState> aurenNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await AurenTvWatchTogetherService.instance.initializeNotificationRouting();
    // Activate App Check before AUREN starts using Firebase services.
    // Enforcement is intentionally configured in Firebase Console after monitoring,
    // so existing development builds are not locked out.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  } catch (error) {
    firebaseError = error;
  }

  ErrorWidget.builder = (details) => const _AurenErrorView();
  await AurenOfflineSyncService.instance.start();
  runApp(AurenApp(firebaseError: firebaseError));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AurenTvWatchTogetherService.instance.setNotificationRoomHandler((roomId) {
      final navigator = aurenNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(MaterialPageRoute(builder: (_) => AurenTvScreen(initialWatchTogetherRoomId: roomId)));
    });
  });
}

class _AurenErrorView extends StatelessWidget {
  const _AurenErrorView();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AUREN',
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 56),
                    SizedBox(height: 16),
                    Text('حدث خطأ غير متوقع في AUREN', textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text('حاول العودة للصفحة السابقة أو إعادة فتح التطبيق.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class AurenApp extends StatelessWidget {
  final Object? firebaseError;

  const AurenApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: aurenNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'AUREN',
        theme: ThemeData.dark(useMaterial3: true),
        home: firebaseError == null
            ? const AurenShell()
            : FirebaseSetupScreen(error: firebaseError!),
      );
}

class FirebaseSetupScreen extends StatelessWidget {
  final Object error;

  const FirebaseSetupScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'AUREN',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Firebase setup is required before AUREN can connect your account, Messenger and Personal AI.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Run flutterfire configure for your Firebase project, then rebuild the app.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Setup error: $error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
