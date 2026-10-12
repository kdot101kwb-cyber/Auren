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
  final selectedRequestIds = <String>{};
  int size = 4;
  String? requestId;
  bool busy = false;

  @override
  void dispose() { country.dispose(); language.dispose(); interest.dispose(); super.dispose(); }

  Future<void> join() async {
    final uid = auth.currentUserId;
    if (uid == null || language.text.trim().isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final id = await service.join(uid: uid, country: country.text, language: language.text,
        interest: interest.text, goal: 'social group', groupSize: size);
      if (!mounted) return;
      setState(() { requestId = id; selectedRequestIds.clear(); });
    } catch (error) {
      _showError('تعذّر الانضمام للانتظار: $error');
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> formSelectedGroup() async {
    final uid = auth.currentUserId;
    final ownRequestId = requestId;
    if (uid == null || ownRequestId == null || busy || selectedRequestIds.length != size - 1) return;
    setState(() => busy = true);
    try {
      final groupId = await service.formGroup(uid: uid, requestIds: [ownRequestId, ...selectedRequestIds]);
      final conversationId = await service.createMessengerGroup(
        groupId: groupId, uid: uid, title: 'AUREN Random Group');
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MessengerScreen(conversationId: conversationId)));
    } catch (error) {
      _showError('ما قدرنا نكوّن المجموعة. حدّث القائمة وحاول تاني. $error');
    } finally { if (mounted) setState(() => busy = false); }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Random Group Connect')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('كوّن مجموعة عشوائية صغيرة للتعارف والنقاش حسب اللغة والاهتمام.'),
        const SizedBox(height: 16),
        _field(country, 'الدولة'),
        _field(language, 'اللغة', onChanged: (_) => setState(() => selectedRequestIds.clear())),
        _field(interest, 'الاهتمام'),
        DropdownButtonFormField<int>(
          initialValue: size,
          decoration: const InputDecoration(labelText: 'حجم المجموعة', border: OutlineInputBorder()),
          items: [3, 4, 5, 6, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n أشخاص'))).toList(),
          onChanged: requestId == null ? (value) => setState(() => size = value ?? 4) : null,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: requestId == null && !busy ? join : null,
          child: Text(busy ? 'جاري التنفيذ...' : requestId == null ? 'انضم للانتظار' : 'أنت في قائمة الانتظار'),
        ),
        if (requestId != null) ...[
          const SizedBox(height: 8),
          Text('اختَر ${size - 1} من المرشحين لتكتمل مجموعة من $size أشخاص.'),
          Text('تم اختيار ${selectedRequestIds.length} من ${size - 1}.'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: !busy && selectedRequestIds.length == size - 1 ? formSelectedGroup : null,
            child: const Text('كوّن المجموعة وافتح Messenger'),
          ),
        ],
        const Divider(height: 32),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.watch(uid: uid, language: language.text, groupSize: size),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Padding(
              padding: EdgeInsets.all(12), child: Text('تعذّر تحميل المرشحين. تحقّق من الاتصال وحاول التحديث.'));
            if (!snapshot.hasData) return const Center(child: Padding(
              padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            final rows = snapshot.data!;
            if (rows.isEmpty) return const Padding(
              padding: EdgeInsets.all(12), child: Text('ما في مرشحين مطابقين حالياً. حنحدّث القائمة تلقائياً.'));
            return Column(children: rows.map((row) {
              final id = row['id'] as String? ?? '';
              final chosen = selectedRequestIds.contains(id);
              final canSelect = requestId != null && (chosen || selectedRequestIds.length < size - 1) && !busy;
              final details = [row['country'], row['language'], row['interest']]
                .whereType<String>().where((value) => value.trim().isNotEmpty).join(' • ');
              return Card(child: CheckboxListTile(
                value: chosen,
                onChanged: canSelect ? (checked) => setState(() {
                  if (checked == true) { selectedRequestIds.add(id); } else { selectedRequestIds.remove(id); }
                }) : null,
                title: Text('مجموعة ${row['groupSize']} أشخاص'),
                subtitle: Text(details),
                controlAffinity: ListTileControlAffinity.leading,
              ));
            }).toList());
          },
        ),
      ]),
    );
  }

  Widget _field(TextEditingController controller, String label, {ValueChanged<String>? onChanged}) =>
    Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
      controller: controller, onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
}
