import 'package:flutter/material.dart';

import '../../../core/models/message.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/ai/ai_gateway.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/actions/action_registry.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/messaging/message_repository.dart';
import '../../../services/messaging/message_safety_repository.dart';
import 'group_details_screen.dart';
import 'message_safety_screen.dart';
import '../../../services/notifications/notification_api.dart';
import '../../../services/users/presence_service.dart';
import '../../../services/memory/memory_repository.dart';

class MessengerScreen extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const MessengerScreen({super.key, this.conversationId, this.initialPrompt});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> with WidgetsBindingObserver {
  final _auth = FirebaseAurenAuthService();
  final _gateway = const ResilientAurenAiGateway();
  final _messagesRepository = FirestoreMessageRepository();
  final _conversationRepository = ConversationRepository();
  final _actionRepository = ActionRepository();
  final _safetyRepository = MessageSafetyRepository();
  final _notificationApi = AurenNotificationApi();
  final _presence = AurenPresenceHeartbeat(AurenPresenceService());
  final _memoryRepository = MemoryRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _conversationId;
  String? _uid;
  bool _loading = true;
  bool _sending = false;
  bool _initialPromptSent = false;
  bool _showDetails = false;
  String? _error;
  bool _isAi = true;
  String _conversationTitle = 'AUREN Messenger';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _uid;
    if (uid == null) return;
    if (state == AppLifecycleState.resumed) {
      _presence.start(uid);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _presence.stop(uid);
    }
  }

  Future<void> _bootstrap() async {
    try {
      _uid = _auth.currentUserId ?? await _auth.signInAnonymously();
      final conversation = widget.conversationId != null
          ? await _conversationRepository.findById(widget.conversationId!)
          : await _conversationRepository.getOrCreateAiConversation(_uid!);
      if (conversation == null || !conversation.memberIds.contains(_uid)) {
        throw StateError('Conversation not found or access denied.');
      }
      _conversationId = conversation.id;
      _presence.start(_uid!);
      _isAi = conversation.isAi;
      _conversationTitle = conversation.title;
      await _conversationRepository.markRead(_conversationId!, _uid!);
      if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
        _controller.text = widget.initialPrompt!.trim();
      }
    } catch (e) {
      _error = 'تعذر تجهيز AUREN Messenger: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _uid == null || _conversationId == null) return;

    _controller.clear();
    setState(() => _sending = true);

    try {
      if (!_isAi) {
        final conversation = await _conversationRepository.findById(_conversationId!);
        final otherUid = conversation?.memberIds.where((id) => id != _uid).firstOrNull;
        if (otherUid != null) {
          final blockedMe = await _safetyRepository.watchBlocked(otherUid, _uid!).first;
          final blockedByMe = await _safetyRepository.watchBlocked(_uid!, otherUid).first;
          if (blockedMe || blockedByMe) {
            throw StateError('Messaging is unavailable because one of the users is blocked.');
          }
        }
      }
      final now = DateTime.now();
      await _messagesRepository.send(AurenMessage(
      id: 'msg_${now.microsecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: _uid!,
      text: text,
        createdAt: now,
      ));
      if (!_isAi) {
        try {
          await _notificationApi.notifyMessage(
            conversationId: _conversationId!,
            messageId: 'msg_${now.microsecondsSinceEpoch}',
            text: text,
          );
        } catch (_) {
          // Notification delivery must never block message delivery.
        }
      }

      if (_isAi) {
        // Only enabled personal memories are shared with the AI gateway.
        // Keep the context bounded so normal chat remains fast and predictable.
        final memories = await _memoryRepository.watch(_uid!).first;
        final enabledMemories = memories.where((m) => m.enabled).take(20).toList();
        final memoryContext = enabledMemories.isEmpty
            ? ''
            : '\\n\\nسياق شخصي محفوظ ومفعّل:\\n' +
                enabledMemories.map((m) => '- ${m.key}: ${m.value}').join('\\n');
        final gatewayMessage = '$text$memoryContext';

        final response = await _gateway.send(
          conversationId: _conversationId!,
          message: gatewayMessage,
        );

        final aiNow = DateTime.now();
        await _messagesRepository.send(AurenMessage(
          id: 'ai_${aiNow.microsecondsSinceEpoch}',
          conversationId: _conversationId!,
          senderId: 'auren-ai',
          text: response.text,
          createdAt: aiNow,
          isAi: true,
        ));

        if (response.action != null && response.action!.trim().isNotEmpty &&
            response.requiresApproval) {
          final actionNow = DateTime.now();
          final actionType = response.action!.trim();
          final definition = AurenActionRegistry.get(actionType);
          if (definition != null) {
            await _actionRepository.create(
              _uid!,
              AurenActionRegistry.fromAi(
                id: 'action_${actionNow.microsecondsSinceEpoch}',
                conversationId: _conversationId!,
                actionType: actionType,
                title: definition.title,
                description: 'طلب تنفيذ: ${definition.title}',
                payload: response.payload,
                createdAt: actionNow,
              ),
            );
          }
        }
      }

      // MessageRepository updates conversation metadata transactionally.
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'فشل الطلب: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الطلب — يمكنك المحاولة مرة ثانية.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final uid = _uid;
    if (uid != null) {
      _presence.stop(uid);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (!_initialPromptSent && !_loading && widget.initialPrompt != null) {
      _initialPromptSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }

    if (_loading || _conversationId == null) {
      if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return Scaffold(
        appBar: AppBar(
        title: const Text('AUREN Messenger'),
        actions: [
          IconButton(
            tooltip: 'Conversation details',
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(_showDetails ? Icons.info : Icons.info_outline),
          ),
        ],
      ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(_error ?? 'تعذر تجهيز المحادثة.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _bootstrap();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('حاول مرة ثانية'),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_conversationTitle),
        actions: [
          if (!_isAi)
            IconButton(
              tooltip: 'Message safety',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AurenMessageSafetyScreen()),
                );
              },
              icon: const Icon(Icons.shield_outlined),
            ),
          if (!_isAi)
            IconButton(
              tooltip: 'Conversation details',
              onPressed: () async {
                final conversation = await _conversationRepository.findById(_conversationId!);
                if (!mounted || conversation == null) return;
                if (conversation.type == 'group') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AurenGroupDetailsScreen(conversation: conversation),
                  ));
                } else {
                  setState(() => _showDetails = !_showDetails);
                }
              },
              icon: const Icon(Icons.info_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showDetails)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text('Conversation: $_conversationId\nAI actions require your approval before execution.'),
            ),
          Expanded(
            child: StreamBuilder<List<AurenMessage>>(
              stream: _messagesRepository.watchConversation(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Could not load messages: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                if (messages.isEmpty) return Center(child: Text(_isAi ? 'ابدأ محادثتك مع AUREN AI' : 'ابدأ المحادثة'));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
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
                          color: mine
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: GestureDetector(
                          onLongPress: () async {
                            if (message.isAi || message.senderId == _uid) return;
                            final reason = await showDialog<String>(
                              context: context,
                              builder: (dialogContext) => SimpleDialog(
                                title: const Text('Message safety'),
                                children: [
                                  SimpleDialogOption(
                                    onPressed: () => Navigator.pop(dialogContext, 'Report'),
                                    child: const Text('Report message'),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () => Navigator.pop(dialogContext, 'Block'),
                                    child: const Text('Block user'),
                                  ),
                                ],
                              ),
                            );
                            if (reason == 'Report') {
                              await _safetyRepository.report(
                                reporterUid: _uid!,
                                conversationId: _conversationId!,
                                messageId: message.id,
                                reason: 'User reported message',
                              );
                            } else if (reason == 'Block') {
                              await _safetyRepository.block(_uid!, message.senderId);
                            }
                          },
                          child: Text(message.text),
                        ),
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
                      decoration: InputDecoration(
                        hintText: _isAi ? 'اكتب لـ AUREN AI…' : 'اكتب رسالة…',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
