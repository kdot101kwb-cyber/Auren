import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/users/user_search_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';

class AurenUserSearchScreen extends StatefulWidget {
  const AurenUserSearchScreen({super.key});

  @override
  State<AurenUserSearchScreen> createState() => _AurenUserSearchScreenState();
}

class _AurenUserSearchScreenState extends State<AurenUserSearchScreen> {
  final c = TextEditingController();
  List<AurenUserProfile> results = [];
  bool loading = false;
  final _conversations = ConversationRepository();

  Future<void> search() async {
    final query = c.text.trim();
    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => loading = true);
    try {
      results = await UserSearchRepository().search(query);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TextField(
        controller: c,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => search(),
        decoration: const InputDecoration(hintText: 'Search people…', border: InputBorder.none),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              final p = results[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty ? NetworkImage(p.photoUrl!) : null,
                  child: p.photoUrl == null || p.photoUrl!.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(p.displayName),
                subtitle: const Text('Open profile or message'),
                trailing: IconButton(
                  tooltip: 'Message',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () async {
                    final uid = FirebaseAurenAuthService().currentUserId;
                    if (uid == null || uid == p.uid) return;
                    try {
                      final conversation = await _conversations.getOrCreateDirectConversation(
                        uid: uid, otherUid: p.uid, otherTitle: p.displayName,
                      );
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: conversation.id)));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر بدء المحادثة: $e')));
                    }
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AurenPublicProfileScreen(profile: p)),
                ),
              );
            },
          ),
  );

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }
}