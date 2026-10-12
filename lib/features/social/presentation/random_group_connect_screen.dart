import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/random_group_connect_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenRandomGroupConnectScreen extends StatefulWidget {
  const AurenRandomGroupConnectScreen({super.key});
  @override
  State<AurenRandomGroupConnectScreen> createState() => _AurenRandomGroupConnectScreenState();
}

class _AurenRandomGroupConnectScreenState extends State<AurenRandomGroupConnectScreen> {
  final auth = FirebaseAurenAuthService();
  final service = AurenRandomGroupConnectService();
  final country = TextEditingController();
  final language = TextEditingController();
  final interest = TextEditingController();
  final Set<String> selectedRequestIds = <String>{};
  int size = 4;
  String? requestId;
  bool submitting = false;

  @override
  void dispose() {
    country.dispose();
    language.dispose();
    interest.dispose();
    super.dispose();
  }

  Future<void> join() async {
    final uid = auth.currentUserId;
    if (uid == null || language.text.trim().isEmpty || submitting) return;
    setState(() => submitting = true);
    try {
      final id = await service.join(
        uid: uid,
        country: country.text,
        language: language.text,
        interest: interest.text,
        goal: 'social group',
        groupSize: size,
      );
      if (!mounted) return;
      setState(() {
        requestId = id;
        submitting = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الانضمام للانتظار: $error')),
        );
      }
    }
  }

  Future<void> formSelectedGroup() async {
    final uid = auth.currentUserId;
    final ownRequestId = requestId;
    if (uid == null || ownRequestId == null || selectedRequestIds.length != size - 1 || submitting) return;
    setState(() => submitting = true);
    try {
      final groupId = await service.formGroup(
        requestId: ownRequestId,
        groupSize: size,
        candidateRequestIds: selectedRequestIds.toList(),
      );
      final conversationId = await service.createMessengerGroup(
        groupId: groupId,
        uid: uid,
        title: 'AUREN Random Group',
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MessengerScreen(conversationId: conversationId),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تكوين المجموعة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Random Group Connect')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('كوّن مجموعة عشوائية صغيرة للتعارف والنقاش حسب اللغة والاهتمام.'),
          const SizedBox(height: 16),
          _f(country, 'الدولة'),
          _f(language, 'اللغة'),
          _f(interest, 'الاهتمام'),
          DropdownButtonFormField<int>(
            initialValue: size,
            decoration: const InputDecoration(labelText: 'حجم المجموعة', border: OutlineInputBorder()),
            items: [3, 4, 5, 6, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n أشخاص'))).toList(),
            onChanged: requestId == null ? (v) => setState(() => size = v ?? 4) : null,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: requestId == null && !submitting ? join : null,
            child: Text(requestId == null ? 'انضم للانتظار' : 'بانتظار المجموعة'),
          ),
          const Divider(height: 32),
          if (requestId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.watch(
                uid: uid,
                language: language.text,
                groupSize: size,
                requestId: requestId,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Text('تعذر تحميل المرشحين الآن. حاول مرة أخرى لاحقاً.');
                }
                if (!snap.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ));
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return const Text('ما في مرشحين مناسبين حالياً. سنبحث مجدداً تلقائياً.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('اختَر ${size - 1} أعضاء معك. المختارون: ${selectedRequestIds.length}/${size - 1}'),
                    ...rows.map((candidate) {
                      final id = candidate['id'] as String;
                      final checked = selectedRequestIds.contains(id);
                      final atLimit = selectedRequestIds.length >= size - 1;
                      final details = [candidate['country'], candidate['language'], candidate['interest']]
                          .whereType<String>().where((value) => value.isNotEmpty).join(' • ');
                      return Card(
                        child: CheckboxListTile(
                          value: checked,
                          onChanged: (!checked && atLimit) ? null : (value) {
                            setState(() {
                              if (value == true) {
                                selectedRequestIds.add(id);
                              } else {
                                selectedRequestIds.remove(id);
                              }
                            });
                          },
                          title: const Text('مرشح للمجموعة'),
                          subtitle: Text(details),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: selectedRequestIds.length == size - 1 && !submitting ? formSelectedGroup : null,
                      child: Text(submitting ? 'جارٍ التكوين...' : 'كوّن المجموعة وافتح Messenger'),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      enabled: requestId == null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );
}
