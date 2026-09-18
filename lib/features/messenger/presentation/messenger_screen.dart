import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../../services/ai/ai_gateway.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final _controller = TextEditingController();
  final _gateway = LocalAiGateway();
  final List<AurenMessage> _messages = [];
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(AurenMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: 'local',
        senderId: 'user',
        text: text,
        createdAt: DateTime.now(),
      ));
      _sending = true;
    });
    final response = await _gateway.send(conversationId: 'local', message: text);
    if (!mounted) return;
    setState(() {
      _messages.add(AurenMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: 'local',
        senderId: 'auren-ai',
        text: response.text,
        createdAt: DateTime.now(),
        isAi: true,
      ));
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Messenger')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final message = _messages[i];
                return Align(
                  alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: message.isAi ? Colors.white12 : Colors.deepPurple,
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب لـ AUREN AI…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
