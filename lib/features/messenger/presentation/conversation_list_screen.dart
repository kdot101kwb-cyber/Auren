import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';
import 'messenger_screen.dart';

class AurenConversationListScreen extends StatefulWidget {
  const AurenConversationListScreen({super.key});
  @override State<AurenConversationListScreen> createState() => _AurenConversationListScreenState();
}
class _AurenConversationListScreenState extends State<AurenConversationListScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = ConversationRepository();
  String? _uid;
  @override void initState() { super.initState(); _bootstrap(); }
  Future<void> _bootstrap() async { try { final uid = _auth.currentUserId ?? await _auth.signInAnonymously(); if (mounted) setState(() => _uid = uid); } catch (_) {} }
  @override Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Messenger')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen())),
        icon: const Icon(Icons.auto_awesome), label: const Text('AUREN AI'),
      ),
      body: uid == null ? const Center(child: CircularProgressIndicator()) : StreamBuilder(
        stream: _repo.watchForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المحادثات: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final conversations = snapshot.data!;
          if (conversations.isEmpty) return const Center(child: Text('ابدأ أول محادثة مع AUREN AI.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: conversations.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) { final c = conversations[i]; return ListTile(
              leading: CircleAvatar(child: Icon(c.isAi ? Icons.auto_awesome : Icons.chat_bubble_outline)),
              title: Text(c.title), subtitle: Text(c.lastMessage?.isNotEmpty == true ? c.lastMessage! : (c.isAi ? 'AUREN AI' : 'محادثة')),
              trailing: Text('${c.updatedAt.hour.toString().padLeft(2, '0')}:${c.updatedAt.minute.toString().padLeft(2, '0')}'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: c.id))),
            ); },
          );
        },
      ),
    );
  }
}