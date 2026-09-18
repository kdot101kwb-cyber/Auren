import 'package:flutter/material.dart';
import 'features/messenger/presentation/messenger_screen.dart';
import 'features/personal_ai/presentation/personal_ai_screen.dart';

void main() => runApp(const AurenApp());

class AurenApp extends StatelessWidget {
  const AurenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AUREN',
    theme: ThemeData.dark(useMaterial3: true),
    home: const AurenHome(),
  );
}

class AurenHome extends StatelessWidget {
  const AurenHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Together, We Build.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Connect. Create. Achieve.'),
        const SizedBox(height: 28),
        Card(child: ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: const Text('Messenger'),
          subtitle: const Text('Chat with people and AUREN AI'),
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
