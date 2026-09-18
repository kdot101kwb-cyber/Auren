import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/messenger/presentation/messenger_screen.dart';
import 'features/home/presentation/auren_home_v2.dart';
import 'features/personal_ai/presentation/personal_ai_screen.dart';
import 'services/auth/auth_service.dart';
import 'services/users/user_repository.dart';
import 'services/messaging/conversation_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AurenApp());
}

class AurenApp extends StatelessWidget {
  const AurenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AUREN',
        theme: ThemeData.dark(useMaterial3: true),
        home: const AurenHomeV2(),
      );
}

class AurenHome extends StatefulWidget {
  const AurenHome({super.key});

  @override
  State<AurenHome> createState() => _AurenHomeState();
}

class _AurenHomeState extends State<AurenHome> {
  final _auth = FirebaseAurenAuthService();
  bool _loading = true;
  String? _uid;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _uid = _auth.currentUserId ?? await _auth.signInAnonymously();
      await UserRepository().getOrCreate(_uid!);
      final conversation = await ConversationRepository().getOrCreateAiConversation(_uid!);
      _conversationId = conversation.id;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Together, We Build.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Connect. Create. Achieve.'),
          if (_uid != null) ...[
            const SizedBox(height: 12),
            Text('Account ready', style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 28),
          Card(child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Messenger'),
            subtitle: Text(_conversationId == null ? 'Chat with people and AUREN AI' : 'AUREN AI • conversation ready'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen())),
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Personal AI'),
            subtitle: const Text('Goals, memory and actions'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAiScreen())),
          )),
        ],
      ),
    );
  }
}
