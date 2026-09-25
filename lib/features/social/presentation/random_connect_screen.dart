import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/social/random_call_service.dart';
import '../../../services/social/random_connect_safety_service.dart';
import '../../../services/social/random_connect_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'random_call_screen.dart';

class AurenRandomConnectScreen extends StatefulWidget {
  const AurenRandomConnectScreen({super.key});
  @override
  State<AurenRandomConnectScreen> createState() => _AurenRandomConnectScreenState();
}

class _AurenRandomConnectScreenState extends State<AurenRandomConnectScreen> {
  final auth = FirebaseAurenAuthService();
  final service = AurenRandomConnectService();
  final safety = AurenRandomConnectSafetyService();
  final callService = AurenRandomCallService();
  final name = TextEditingController();
  final country = TextEditingController();
  final language = TextEditingController();
  final interest = TextEditingController();
  final goal = TextEditingController();

  String? requestId;
  bool busy = false;
  final Set<String> skippedIds = <String>{};

  @override
  void dispose() {
    for (final c in [name, country, language, interest, goal]) {
      c.dispose();
    }
    super.dispose();
  }

  void msg(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> join() async {
    final uid = auth.currentUserId;
    if (uid == null || language.text.trim().isEmpty) {
      msg('اكتب اللغة أولاً.');
      return;
    }
    setState(() => busy = true);
    try {
      skippedIds.clear();
      final id = await service.join(
        uid: uid,
        displayName: name.text,
        country: country.text,
        language: language.text,
        interest: interest.text,
        goal: goal.text,
      );
      if (mounted) setState(() => requestId = id);
    } catch (_) {
      msg('تعذر بدء البحث.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancel() async {
    final uid = auth.currentUserId;
    final id = requestId;
    if (uid == null || id == null) return;
    setState(() => busy = true);
    try {
      await service.cancel(uid, id);
      if (mounted) setState(() => requestId = null);
    } catch (_) {
      msg('تعذر إلغاء الانتظار.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void skip(AurenRandomMatch m) {
    setState(() => skippedIds.add(m.id));
  }

  void resetSkipped() {
    setState(() => skippedIds.clear());
  }

  Future<void> connect(AurenRandomMatch m) async {
    final uid = auth.currentUserId;
    if (uid == null || busy) return;
    setState(() => busy = true);
    try {
      final other = await service.connect(uid, m.id);
      if (other == null) {
        skip(m);
        msg('الشخص لم يعد متاحاً. انتقلت للمطابقة التالية.');
        return;
      }
      final c = await ConversationRepository().getOrCreateDirectConversation(
        uid: uid,
        otherUid: other,
        otherTitle: m.displayName,
      );
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MessengerScreen(conversationId: c.id),
          ),
        );
      }
    } catch (_) {
      msg('تعذر فتح المحادثة.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> startCall(AurenRandomMatch m, String kind) async {
    final uid = auth.currentUserId;
    if (uid == null || busy || m.uid.isEmpty || m.uid == uid) return;
    setState(() => busy = true);
    try {
      final callId = await callService.create(
        callerUid: uid,
        calleeUid: m.uid,
        kind: kind,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AurenRandomCallScreen(
            callId: callId,
            caller: true,
            kind: kind,
            otherName: m.displayName,
          ),
        ),
      );
    } catch (_) {
      msg('تعذر بدء المكالمة.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> report(AurenRandomMatch m) async {
    final uid = auth.currentUserId;
    if (uid == null || uid == m.uid) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('الإبلاغ عن المستخدم'),
        children: [
          for (final v in ['محتوى غير مناسب', 'إزعاج أو إساءة', 'احتيال', 'أخرى'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, v),
              child: Text(v),
            ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await safety.reportUser(
        reporterUid: uid,
        reportedUid: m.uid,
        reason: reason,
      );
      msg('تم إرسال البلاغ للمراجعة.');
    } catch (_) {
      msg('تعذر إرسال البلاغ.');
    }
  }

  Future<void> block(AurenRandomMatch m) async {
    final uid = auth.currentUserId;
    if (uid == null || uid == m.uid) return;
    try {
      await safety.block(uid: uid, blockedUid: m.uid);
      skip(m);
      msg('تم حظر المستخدم وإخفاؤه من النتائج.');
    } catch (_) {
      msg('تعذر الحظر.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = auth.currentUserId;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Random Connect')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('تواصل عشوائياً حسب اللغة والاهتمام والهدف.'),
          const SizedBox(height: 16),
          ...[
            _f(name, 'الاسم الظاهر'),
            _f(country, 'الدولة'),
            _f(language, 'اللغة'),
            _f(interest, 'الاهتمام'),
            _f(goal, 'الهدف'),
          ],
          FilledButton.icon(
            onPressed: busy ? null : (requestId == null ? join : cancel),
            icon: Icon(requestId == null ? Icons.radar : Icons.close),
            label: Text(requestId == null ? 'ابدأ البحث' : 'إلغاء الانتظار'),
          ),
          if (requestId != null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          const Divider(height: 32),
          StreamBuilder<List<AurenRandomMatch>>(
            stream: service.watchWaiting(
              country: country.text,
              language: language.text,
              interest: interest.text,
              goal: goal.text,
            ),
            builder: (context, snapshot) {
              final items = (snapshot.data ?? const <AurenRandomMatch>[])
                  .where((x) => x.uid != me && !skippedIds.contains(x.id))
                  .toList();

              if (items.isEmpty) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('ما في أشخاص متاحين بالمطابقة الحالية.'),
                      ),
                    ),
                    if (skippedIds.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: resetSkipped,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إظهار المطابقات المتخطاة'),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'أفضل المطابقات (' + items.length.toString() + ')',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (skippedIds.isNotEmpty)
                        TextButton(
                          onPressed: resetSkipped,
                          child: const Text('إظهار الكل'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (m) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(m.displayName),
                        subtitle: Text(
                          [
                            m.country,
                            m.language,
                            m.interest,
                            m.goal,
                          ].where((v) => v.isNotEmpty).join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'connect') connect(m);
                            if (v == 'audio') startCall(m, 'audio');
                            if (v == 'video') startCall(m, 'video');
                            if (v == 'skip') skip(m);
                            if (v == 'report') report(m);
                            if (v == 'block') block(m);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'connect',
                              child: Text('Connect / Messenger'),
                            ),
                            PopupMenuItem(
                              value: 'audio',
                              child: Text('Voice call'),
                            ),
                            PopupMenuItem(
                              value: 'video',
                              child: Text('Video call'),
                            ),
                            PopupMenuItem(
                              value: 'skip',
                              child: Text('التالي / تخطي'),
                            ),
                            PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Text('Block'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String l) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
