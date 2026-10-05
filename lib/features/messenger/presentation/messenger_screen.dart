import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/message.dart';
import '../../../core/models/action_request.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/ai/ai_gateway.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/messaging/message_repository.dart';
import '../../../services/messaging/message_safety_repository.dart';
import '../../../services/messaging/typing_service.dart';
import 'group_details_screen.dart';
import 'message_safety_screen.dart';
import '../../../services/users/presence_service.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';

class MessengerScreen extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;
  final ValueChanged<String>? onAiResponse;

  const MessengerScreen({super.key, this.conversationId, this.initialPrompt, this.onAiResponse});

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


      if (_isAi) {
        // The callable gateway builds conversation context server-side.
        // Keep the client request limited to the user's actual message.
        final response = await _gateway.send(
          conversationId: _conversationId!,
          message: text,
          requestId: messageId,
        );
        widget.onAiResponse?.call(response.text);

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
      await _actionRepository.approve(action.id);
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
      await _actionRepository.reject(action.id);
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

  Future<void> _cancelAction(AurenActionRequest action) async {
    if (_uid == null || (action.status != 'pending' && action.status != 'approved')) return;
    try {
      await _actionRepository.cancel(action.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء الطلب: ${action.title}')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'تعذر إلغاء الطلب.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إلغاء الطلب.')),
        );
      }
    }
  }

  Future<void> _executeAction(AurenActionRequest action) async {
    if (_uid == null || action.status != 'approved') return;
    try {
      final status = await _actionRepository.execute(action.id);
      final refreshed = await _actionRepository.get(_uid!, action.id);
      final result = refreshed?.result;
      if (status != 'completed') {
        throw StateError('Action did not complete.');
      }
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
          case 'goal_created':
            message = 'تم إنشاء الهدف بنجاح.';
            break;
          case 'message_sent':
            message = 'تم إرسال الرسالة بنجاح.';
            break;
          case 'content_job_created':
            message = 'تم إنشاء مهمة المحتوى وبدأت في AUREN Entertainment.';
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

  Future<void> _showActionDetails(AurenActionRequest action) async {
    final payload = action.payload;
    final payloadText = payload.entries
        .map((entry) => entry.key + ': ' + entry.value.toString())
        .join('\n');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final pending = action.status == 'pending';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 10),
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
                      return Center(child: Text('Could not load read status: ${readSnapshot.error}'));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not load messages: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!;
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(child: Text(message.text)),
                                  _messageStatus(message, readAt),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
