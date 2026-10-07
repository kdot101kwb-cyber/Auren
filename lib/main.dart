import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n/auren_localizations.dart';
import 'core/i18n/auren_locale_controller.dart';

import 'firebase_options.dart';
import 'features/shell/presentation/auren_shell.dart';
import 'features/tv/presentation/auren_tv_screen.dart';
import 'features/entertainment/presentation/auren_sports_entertainment_screen.dart';
import 'features/entertainment/presentation/auren_sports_detail_screen.dart';
import 'services/tv/auren_tv_watch_together_service.dart';
import 'services/offline/auren_offline_sync_service.dart';
import 'services/notifications/auren_fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> aurenNavigatorKey = GlobalKey<NavigatorState>();
final AurenLocaleController aurenLocaleController = AurenLocaleController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Activate App Check before any authenticated Firebase callable/service traffic.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await AurenTvWatchTogetherService.instance.initializeNotificationRouting();
    await AurenFcmService.instance.initialize();
  } catch (error) {
    firebaseError = error;
  }

  await aurenLocaleController.load();
  ErrorWidget.builder = (details) => const _AurenErrorView();
  await AurenOfflineSyncService.instance.start();
  runApp(AurenApp(firebaseError: firebaseError));
  AurenFcmService.instance.setOpenHandler((message) {
    final data = message.data;
    if (data['type'] == 'goal' || data['type'] == 'kickoff' || data['type'] == 'red_card' || data['type'] == 'full_time') {
      final navigator = aurenNavigatorKey.currentState;
      if (navigator == null) return;
      final fixtureId = (data['fixtureId'] ?? '').toString().trim();
      if (fixtureId.isNotEmpty) {
        navigator.push(MaterialPageRoute(builder: (_) => AurenSportsDetailScreen(
          sport: 'football', resource: 'game_details',
          data: {'fixtureId': fixtureId, 'id': fixtureId},
        )));
      } else {
        navigator.push(MaterialPageRoute(builder: (_) => const AurenSportsEntertainmentScreen()));
      }
    }
  });
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: aurenLocaleController,
        builder: (context, _) => MaterialApp(
          navigatorKey: aurenNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'AUREN',
          theme: ThemeData.dark(useMaterial3: true),
          locale: aurenLocaleController.languageCode == null
              ? null
              : Locale(aurenLocaleController.languageCode!),
          supportedLocales: AurenLocalizations.supportedLocales,
          localizationsDelegates: const [
            AurenLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: firebaseError == null
              ? const AurenShell()
              : FirebaseSetupScreen(error: firebaseError!),
        ),
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
