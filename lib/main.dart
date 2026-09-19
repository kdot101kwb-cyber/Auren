import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/shell/presentation/auren_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error;
  }

  runApp(AurenApp(firebaseError: firebaseError));
}

class AurenApp extends StatelessWidget {
  final Object? firebaseError;

  const AurenApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
