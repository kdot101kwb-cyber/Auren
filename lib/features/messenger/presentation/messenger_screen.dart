import 'package:flutter/material.dart';

import '../../../core/models/message.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/ai/https_ai_gateway.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/messaging/message_repository.dart';

class MessengerScreen extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const MessengerScreen({super.key, this.conversationId, this.initialPrompt});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final _auth = FirebaseAurenAuthService();
  final _gateway = const HttpsAurenAiGateway();
  final _messagesRepository = FirestoreMessageRepository();
  final _conversationRepository = ConversationRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _conversationId;
  String? _uid;
  bool _loading = true;
  bool _sending = false;
  bool _initialPromptSent = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _uid = _auth.currentUserId ?? await _auth.signInAnonymously();
      _conversationId = widget.conversationId ??
          (await _conversationRepository.getOrCreateAiConversation(_uid!)).id;
      if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
        _controller.text = widget.initialPrompt!.trim();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _uid == null || _conversationId == null) return;

    _controller.clear();
    setState(() => _sending = true);

    final now = DateTime.now();
    final userMessage = AurenMessage(
      id: 'msg_${now.microsecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: _uid!,
      text: text,
      createdAt: now,
    );

    try {
      await _messagesRepository.send(userMessage);
      final response = await _gateway.send(
        conversationId: _conversationId!,
        message: text,
      );

      final aiNow = DateTime.now();
      await _messagesRepository.send(
        AurenMessage(
          id: 'ai_${aiNow.microsecondsSinceEpoch}',
          conversationId: _conversationId!,
          senderId: 'auren-ai',
          text: response.text,
          createdAt: aiNow,
          isAi: true,
        ),
      );
      await _conversationRepository.touch(_conversationId!);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialPromptSent && !_loading && widget.initialPrompt != null) {
      _initialPromptSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }

    if (_loading || _conversationId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Messenger')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AurenMessage>>(
              stream: _messagesRepository.watchConversation(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Could not load messages: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                if (messages.isEmpty) return const Center(child: Text('ابدأ محادثتك مع AUREN AI'));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = !message.isAi && message.senderId == _uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: mine ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'اكتب لـ AUREN AI…', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
