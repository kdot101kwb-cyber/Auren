import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/creator/creator_studio_repository.dart';
import 'creator_growth_screen.dart';
import 'creator_earnings_screen.dart';

class AurenCreatorStudioScreen extends StatefulWidget {
  const AurenCreatorStudioScreen({super.key});
  @override State<AurenCreatorStudioScreen> createState() => _AurenCreatorStudioScreenState();
}

class _AurenCreatorStudioScreenState extends State<AurenCreatorStudioScreen> {
  final _repo = AurenCreatorStudioRepository();
  final _text = TextEditingController();
  final _media = TextEditingController();
  String _mediaType = 'none';
  bool _publishing = false;
  Future<AurenCreatorStats>? _stats;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override void initState() {
    super.initState();
    final uid = _uid;
    if (uid != null) _stats = _repo.loadStats(uid);
  }

  @override void dispose() { _text.dispose(); _media.dispose(); super.dispose(); }

  Future<void> _publish() async {
    final uid = _uid;
    if (uid == null || _publishing) return;
    setState(() => _publishing = true);
    try {
      await _repo.publish(uid: uid, text: _text.text, mediaUrl: _media.text, mediaType: _mediaType);
      _text.clear();
      _media.clear();
      _refreshStats();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المحتوى في Creator Studio.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _refreshStats() {
    final uid = _uid;
    if (uid != null) setState(() => _stats = _repo.loadStats(uid));
  }

  @override Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Studio'), actions: [IconButton(onPressed: _refreshStats, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text('Creator Studio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('أنشئ وانشر وتابع أداء محتواك من مكان واحد. صفحة Creator تعتمد على AI Profile Mode.'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Creator Earnings'),
              subtitle: const Text('تابع الدعم المسجل وحالة التسوية من مكان واحد.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AurenCreatorEarningsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: const Text('Creator Growth Engine'),
              subtitle: const Text('خطط للمحتوى، راقب الأداء، وجدول أفكارك القادمة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AurenCreatorGrowthScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<AurenCreatorStats>(
            future: _stats,
            builder: (context, snap) {
              final data = snap.data;
              if (snap.connectionState == ConnectionState.waiting && data == null) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
              return Row(children: [
                _stat('المحتوى', '${data?.posts ?? 0}', Icons.grid_view_rounded),
                _stat('الإعجابات', '${data?.likes ?? 0}', Icons.favorite_border),
                _stat('Media', '${data?.mediaPosts ?? 0}', Icons.perm_media_outlined),
              ]);
            },
          ),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Publish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(controller: _text, minLines: 4, maxLines: 8, maxLength: 4000, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اكتب فكرة، قصة، إعلان، فيديو أو محتوى لجمهورك...')),
            const SizedBox(height: 8),
            TextField(controller: _media, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Media URL (اختياري)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _mediaType,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'نوع الوسائط'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون')),
                DropdownMenuItem(value: 'image', child: Text('صورة')),
                DropdownMenuItem(value: 'video', child: Text('فيديو')),
                DropdownMenuItem(value: 'audio', child: Text('صوت')),
              ],
              onChanged: (v) => setState(() => _mediaType = v ?? 'none'),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _publishing ? null : _publish, icon: const Icon(Icons.publish_rounded), label: Text(_publishing ? 'جاري النشر...' : 'نشر'))),
          ]))),
          const SizedBox(height: 16),
          const Text('Your content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.watchRecentPosts(uid),
            builder: (context, snap) {
              if (snap.hasError) return Text('تعذر تحميل المحتوى: ${snap.error}');
              final posts = snap.data ?? const <Map<String, dynamic>>[];
              if (posts.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لسه ما نشرت محتوى. ابدأ بأول منشور.')));
              return Column(children: posts.map((post) {
                final id = post['id'].toString();
                final text = post['text'].toString();
                final likes = (post['likes'] as num?)?.toInt() ?? 0;
                return Card(child: ListTile(
                  title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$likes إعجاب • ${post['mediaType'] ?? 'none'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try { await _repo.delete(uid, id); _refreshStats(); }
                      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحذف: $e'))); }
                    },
                  ),
                ));
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Icon(icon), const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]))),
  );
}
