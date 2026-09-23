import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/message.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/ai/ai_gateway.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/messaging/message_repository.dart';
import '../../../services/messaging/message_safety_repository.dart';
import '../../../services/messaging/typing_service.dart';
import 'group_details_screen.dart';
import 'message_safety_screen.dart';
import '../../../services/notifications/notification_api.dart';
import '../../../services/users/presence_service.dart';

class MessengerScreen extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const MessengerScreen({super.key, this.conversationId, this.initialPrompt});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> with WidgetsBindingObserver {
  final _auth = FirebaseAurenAuthService();
  final _gateway = ResilientAurenAiGateway();
  final _messagesRepository = FirestoreMessageRepository();
  final _conversationRepository = ConversationRepository();
  final _actionRepository = ActionRepository();
  final _safetyRepository = MessageSafetyRepository();
  final _notificationApi = AurenNotificationApi();
  final _presenceService = AurenPresenceService();
  late final AurenPresenceHeartbeat _presence;
  final _typing = AurenTypingService();
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
  String? _otherUid;
  DateTime? _lastReadMarkAt;

  @override
  void initState() {
    super.initState();
    _presence = AurenPresenceHeartbeat(_presenceService);
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
      _uid = _auth.currentUserId;
      if (_uid == null) throw StateError('Please sign in first.');
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
      _otherUid = _isAi ? null : conversation.memberIds.where((id) => id != _uid).firstOrNull;
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
    if (_conversationId != null && _uid != null) await _typing.setTyping(_conversationId!, _uid!, false);
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
      final messageId = 'msg_${now.microsecondsSinceEpoch}';
      await _messagesRepository.send(AurenMessage(
        id: messageId,
        conversationId: _conversationId!,
        senderId: _uid!,
        text: text,
        createdAt: now,
      ));

      if (!_isAi) {
        try {
          await _notificationApi.notifyMessage(
            conversationId: _conversationId!,
            messageId: messageId,
            text: text,
          );
        } catch (_) {}
      }

      if (_isAi) {
        // The callable gateway builds conversation context server-side.
        // Keep the client request limited to the user's actual message.
        final response = await _gateway.send(
          conversationId: _conversationId!,
          message: text,
          requestId: messageId,
        );

        // The gateway persists the AI-authored message server-side.
        // The client must never be allowed to impersonate "auren-ai".
        // Approval-gated actions are created and validated by the server.
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'فشل الطلب: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الطلب — يمكنك المحاولة مرة ثانية.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _approveAction(AurenActionRequest action) async {
    if (_uid == null) return;
    try {
      await _actionRepository.setStatus(_uid!, action.id, 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت الموافقة: ${action.title}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذرت الموافقة على الطلب.')),
        );
      }
    }
  }

  Future<void> _rejectAction(AurenActionRequest action) async {
    if (_uid == null || action.status != 'pending') return;
    try {
      await _actionRepository.setStatus(_uid!, action.id, 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم رفض الطلب: ${action.title}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر رفض الطلب.')),
        );
      }
    }
  }

  Future<void> _executeAction(AurenActionRequest action) async {
    if (_uid == null || action.status != 'approved') return;
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('executeAurenAction');
      final response = await callable.call(<String, dynamic>{
        'actionId': action.id,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      final result = data['result'];
      String message = 'تم تنفيذ العملية بنجاح.';
      if (result is Map) {
        switch (result['type']?.toString()) {
          case 'note_created':
            message = 'تم إنشاء الملاحظة بنجاح.';
            break;
          case 'memory_saved':
            message = 'تم حفظ المعلومة في ذاكرة AUREN.';
            break;
          case 'echo':
            message = 'تم تنفيذ الطلب بنجاح.';
            break;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'تعذر تنفيذ الطلب.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تنفيذ الطلب.')),
        );
      }
    }
  }

  Widget _pendingActionsPanel() {
    if (!_isAi || _uid == null || _conversationId == null) return const SizedBox.shrink();
    return StreamBuilder<List<AurenActionRequest>>(
      stream: _actionRepository.watchOutstandingForConversation(_uid!, _conversationId!),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? const <AurenActionRequest>[];
        return Column(
          children: [
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(
                  children: actions.take(3).map((action) {
                    final pending = action.status == 'pending';
                    final approved = action.status == 'approved';
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(approved ? Icons.verified_outlined : Icons.auto_awesome),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                Icon(pending ? Icons.lock_outline : Icons.check_circle_outline, size: 20),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(action.description),
                            const SizedBox(height: 8),
                            Text(
                              pending ? 'سيطلب AUREN موافقتك قبل التنفيذ.' : 'تمت الموافقة — جاهز للتنفيذ.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (pending) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _rejectAction(action),
                                      icon: const Icon(Icons.close),
                                      label: const Text('رفض'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: pending ? () => _approveAction(action) : () => _executeAction(action),
                                    icon: Icon(pending ? Icons.check : Icons.play_arrow),
                                    label: Text(pending ? 'موافقة' : 'تنفيذ'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            _actionHistoryPanel(),
          ],
        );
      },
    );
  }

  Widget _actionHistoryPanel() {
    if (!_isAi || _uid == null || _conversationId == null) return const SizedBox.shrink();
    return StreamBuilder<List<AurenActionRequest>>(
      stream: _actionRepository.watchHistory(_uid!, limit: 20),
      builder: (context, snapshot) {
        final history = (snapshot.data ?? const <AurenActionRequest>[])
            .where((action) => action.conversationId == _conversationId)
            .take(5)
            .toList();
        if (history.isEmpty) return const SizedBox.shrink();

        String statusLabel(String status) {
          switch (status) {
            case 'completed': return 'تم التنفيذ بنجاح';
            case 'failed': return 'تعذر تنفيذ العملية';
            case 'rejected': return 'تم رفض العملية';
            case 'executing': return 'جارٍ التنفيذ';
            default: return status;
          }
        }

        IconData statusIcon(String status) {
          switch (status) {
            case 'completed': return Icons.check_circle_outline;
            case 'failed': return Icons.error_outline;
            case 'rejected': return Icons.cancel_outlined;
            default: return Icons.history;
          }
        }

        String friendlyResult(AurenActionRequest action) {
          final result = action.result;
          if (result is Map) {
            final type = result['type']?.toString();
            if (type == 'note_created') return 'تم إنشاء الملاحظة بنجاح.';
            if (type == 'memory_saved') return 'تم حفظ المعلومة في ذاكرة AUREN.';
            if (type == 'echo') return 'تم تنفيذ الطلب بنجاح.';
          }
          if (result == null || result.toString().trim().isEmpty) return statusLabel(action.status);
          return result.toString();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Card(
            child: ExpansionTile(
              leading: const Icon(Icons.history),
              title: const Text('سجل AUREN Actions'),
              subtitle: Text(history.length.toString() + ' عمليات سابقة'),
              children: history.map((action) {
                return ListTile(
                  dense: true,
                  leading: Icon(statusIcon(action.status)),
                  title: Text(action.title),
                  subtitle: Text(
                    friendlyResult(action),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _messageMenu(AurenMessage message) async {
    if (_uid == null) return;
    final canModerate = !message.isAi && message.senderId != _uid;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy message'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (canModerate)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report message'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
            if (canModerate)
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Block user'),
                onTap: () => Navigator.pop(context, 'block'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied.')),
        );
      }
    } else if (choice == 'report') {
      await _safetyRepository.report(
        reporterUid: _uid!,
        conversationId: _conversationId!,
        messageId: message.id,
        reason: 'User reported message',
      );
    } else if (choice == 'block') {
      await _safetyRepository.block(_uid!, message.senderId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final uid = _uid;
    if (uid != null) {
      _presence.stop(uid);
      if (_conversationId != null) _typing.setTyping(_conversationId!, uid, false);
    }
    _typing.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _presenceHeader() {
    if (_isAi || _otherUid == null) return const SizedBox.shrink();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _presenceService.watch(_otherUid!),
      builder: (_, snapshot) {
        final data = snapshot.data;
        final online = data?['online'] == true;
        final lastSeen = data?['lastSeen'];
        String label = online ? 'Online' : 'Offline';
        if (!online && lastSeen is Timestamp) {
          final d = DateTime.now().difference(lastSeen.toDate());
          if (d.inMinutes < 1) label = 'Last seen just now';
          else if (d.inMinutes < 60) label = 'Last seen ${d.inMinutes}m ago';
          else if (d.inHours < 24) label = 'Last seen ${d.inHours}h ago';
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.circle, size: 8, color: online ? Colors.green : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ]),
        );
      },
    );
  }

  Widget _messageStatus(AurenMessage message, DateTime? readAt) {
    if (_isAi || _uid == null || message.senderId != _uid) return const SizedBox.shrink();
    final read = readAt != null && !readAt.isBefore(message.createdAt);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Icon(Icons.done_all, size: 14, color: read ? Theme.of(context).colorScheme.primary : null),
    );
  }

  Widget build(BuildContext context) {
    if (!_initialPromptSent && !_loading && widget.initialPrompt != null) {
      _initialPromptSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }

    if (_loading || _conversationId == null) {
      if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return Scaffold(
        appBar: AppBar(title: const Text('AUREN Messenger')),
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
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenMessageSafetyScreen()),
              ),
              icon: const Icon(Icons.shield_outlined),
            ),
          if (!_isAi)
            IconButton(
              tooltip: 'Conversation details',
              onPressed: () async {
                final conversation = await _conversationRepository.findById(_conversationId!);
                if (!mounted || conversation == null) return;
                if (conversation.type == 'group') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AurenGroupDetailsScreen(conversation: conversation),
                    ),
                  );
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
          _presenceHeader(),
          _pendingActionsPanel(),
          if (_isAi && !_sending && _controller.text.isEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  'خطط لي يومي',
                  'ساعدني في هدفي',
                  'ابحث عن فرصة',
                  'اكتشف شيئًا جديدًا',
                ].map((prompt) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(prompt),
                    onPressed: () {
                      _controller.text = prompt;
                      _controller.selection =
                          TextSelection.collapsed(offset: prompt.length);
                      setState(() {});
                    },
                  ),
                )).toList(),
              ),
            ),
          if (!_isAi && _otherUid != null)
            StreamBuilder<bool>(
              stream: _typing.watchTyping(_conversationId!, _otherUid!),
              builder: (_, snapshot) => snapshot.data == true
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('يكتب الآن…'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (_showDetails)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                'Conversation: ' + _conversationId! +
                    '\nAI actions require your approval before execution.',
              ),
            ),
          Expanded(
            child: StreamBuilder<DateTime?>(
              stream: _isAi || _otherUid == null
                  ? null
                  : _conversationRepository.watchReadAt(_conversationId!, _otherUid!),
              builder: (context, readSnapshot) {
                final readAt = readSnapshot.data;
                return StreamBuilder<List<AurenMessage>>(
              stream: _messagesRepository.watchConversation(_conversationId!),
              builder: (context, snapshot) {
                if (readSnapshot.hasError) {
                  return Center(child: Text('Could not load read status: ' + readSnapshot.error.toString()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load messages: ' + snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                // Avoid a Firestore write on every message-stream rebuild.
                if (!_isAi && _uid != null) {
                  final now = DateTime.now();
                  final last = _lastReadMarkAt;
                  if (last == null || now.difference(last) >= const Duration(seconds: 5)) {
                    _lastReadMarkAt = now;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _conversationRepository.markRead(_conversationId!, _uid!);
                      }
                    });
                  }
                }
                if (messages.isEmpty) {
                  return Center(
                    child: Text(_isAi ? 'ابدأ محادثتك مع AUREN AI' : 'ابدأ المحادثة'),
                  );
                }

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
                          onLongPress: () => _messageMenu(message),
                          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Flexible(child: Text(message.text)),
                            _messageStatus(message, readAt),
                          ]),
                        ),
                      ),
                    );
                  },
                );
                },
              );
            },
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
                      onChanged: (value) {
                        setState(() {});
                        if (!_isAi && _uid != null && _conversationId != null) {
                          _typing.setTyping(_conversationId!, _uid!, value.trim().isNotEmpty);
                          if (value.trim().isNotEmpty) _typing.scheduleStop(_conversationId!, _uid!);
                        }
                      },
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
