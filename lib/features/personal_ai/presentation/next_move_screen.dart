import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/next_move_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenNextMoveScreen extends StatefulWidget {
  const AurenNextMoveScreen({super.key});
  @override State<AurenNextMoveScreen> createState() => _AurenNextMoveScreenState();
}

class _AurenNextMoveScreenState extends State<AurenNextMoveScreen> {
  final _auth = FirebaseAurenAuthService();
  late Future<AurenNextMove> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AurenNextMove> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null) throw StateError('يجب تسجيل الدخول أولاً.');
    return NextMoveService().build(uid);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AUREN Next Move'),
      actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
    ),
    body: FutureBuilder<AurenNextMove>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('تعذر بناء الخطوة التالية: ${snapshot.error}'),
          ));
        }
        final move = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.route_outlined),
                    SizedBox(width: 8),
                    Text('خطوتك التالية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  Text(move.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(move.action, style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 14),
                  Text('الوحدة: ${move.module}'),
                  const SizedBox(height: 6),
                  Text('درجة الثقة في الاقتراح: ${move.confidence}%'),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('ليه دي الخطوة؟'),
                subtitle: Text(move.reason),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('بدائل', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...move.alternatives.map((x) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [const Icon(Icons.chevron_right), const SizedBox(width: 6), Expanded(child: Text(x))]),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: move.toPrompt())),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('خلّي AUREN يبدأ الخطوة'),
            ),
          ],
        );
      },
    ),
  );
}