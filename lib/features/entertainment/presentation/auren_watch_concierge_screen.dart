import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenWatchConciergeScreen extends StatefulWidget {
  const AurenWatchConciergeScreen({super.key});
  @override State<AurenWatchConciergeScreen> createState() => _AurenWatchConciergeScreenState();
}

class _AurenWatchConciergeScreenState extends State<AurenWatchConciergeScreen> {
  final _prompt = TextEditingController();
  String _mood = 'الكل';
  String _type = 'الكل';
  int _minutes = 60;
  Map<String, Map<String, dynamic>> _signals = const {};
  List<AurenEntertainmentItem> _plan = const [];

  static const _moods = ['الكل', 'خفيف', 'هادئ', 'حماس', 'غموض', 'رومانسي', 'كوميدي', 'اكتشاف'];
  static const _types = ['الكل', 'Global Series', 'Anime', 'Short', 'Book'];

  @override
  void initState() { super.initState(); _prompt.addListener(_inferIntent); }

  @override
  void dispose() { _prompt.removeListener(_inferIntent); _prompt.dispose(); super.dispose(); }

  void _inferIntent() {
    final text = _prompt.text.toLowerCase();
    const moodKeys = <String, List<String>>{
      'خفيف': ['خفيف', 'light', 'short', 'سريع'],
      'هادئ': ['هادئ', 'calm', 'relax', 'مريح'],
      'حماس': ['حماس', 'action', 'exciting', 'مغامرة'],
      'غموض': ['غموض', 'mystery', 'thriller', 'تحقيق'],
      'رومانسي': ['رومانسي', 'romance', 'love'],
      'كوميدي': ['كوميدي', 'comedy', 'ضحك'],
      'اكتشاف': ['اكتشاف', 'documentary', 'culture', 'ثقافة'],
    };
    const typeKeys = <String, List<String>>{
      'Anime': ['anime', 'أنمي'],
      'Global Series': ['مسلسل', 'series', 'سلسلة'],
      'Short': ['short', 'شورت', 'قصير'],
      'Book': ['كتاب', 'book', 'manga', 'مانجا'],
    };
    for (final e in moodKeys.entries) {
      if (e.value.any(text.contains) && _mood != e.key && mounted) { setState(() => _mood = e.key); break; }
    }
    for (final e in typeKeys.entries) {
      if (e.value.any(text.contains) && _type != e.key && mounted) { setState(() => _type = e.key); break; }
    }
    final h = RegExp(r'(\d+)\s*(?:ساعة|ساعات|hour|hours|hr|hrs)').firstMatch(text);
    final m = RegExp(r'(\d+)\s*(?:دقيقة|دقائق|minute|minutes|min|mins)').firstMatch(text);
    int? parsed;
    if (h != null) parsed = (int.tryParse(h.group(1)!) ?? 1) * 60;
    if (h == null && m != null) parsed = int.tryParse(m.group(1)!);
    if (parsed != null && mounted) {
      final next = parsed!.clamp(10, 240);
      if (next != _minutes) setState(() => _minutes = next);
    }
  }

  double _score(AurenEntertainmentItem item) {
    final text = '${item.title} ${item.description} ${item.type}'.toLowerCase();
    final prompt = _prompt.text.trim().toLowerCase();
    var score = 0.0;
    if (_type == 'الكل' || item.type == _type) score += 8;
    if (_mood != 'الكل' && text.contains(_mood.toLowerCase())) score += 12;
    final words = prompt.split(RegExp(r'\s+')).where((x) => x.length > 2).toSet();
    score += words.where(text.contains).length * 3;
    final signal = _signals[item.id];
    if (signal != null) {
      score += ((signal['watchSeconds'] as num?)?.toDouble() ?? 0) * .01;
      score += ((signal['views'] as num?)?.toDouble() ?? 0) * 1.5;
      score += ((signal['completions'] as num?)?.toDouble() ?? 0) * 5;
      score -= ((signal['skips'] as num?)?.toDouble() ?? 0) * 3;
    }
    return score;
  }

  List<AurenEntertainmentItem> _buildPlan(List<AurenEntertainmentItem> items) {
    final usable = items.where((x) => x.mediaUrl.isNotEmpty || x.imageUrl.isNotEmpty).toList();
    usable.sort((a, b) => _score(b).compareTo(_score(a)));
    if (usable.isEmpty) return const [];
    final target = (_minutes / 30).ceil().clamp(1, 8);
    final result = <AurenEntertainmentItem>[];
    final creators = <String>{};
    for (final item in usable) {
      if (result.length >= target) break;
      if (item.creatorId.isNotEmpty && creators.contains(item.creatorId)) continue;
      result.add(item);
      if (item.creatorId.isNotEmpty) creators.add(item.creatorId);
    }
    for (final item in usable) {
      if (result.length >= target) break;
      if (!result.any((x) => x.id == item.id)) result.add(item);
    }
    return result;
  }

  Future<void> _generate(List<AurenEntertainmentItem> source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snap = await EntertainmentRepository().db.collection('users').doc(uid)
            .collection('entertainmentSignals').get();
        _signals = {for (final d in snap.docs) d.id: d.data()};
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _plan = _buildPlan(source));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Watch Concierge')),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: EntertainmentRepository().watchItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المحتوى: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final source = snapshot.data ?? const <AurenEntertainmentItem>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ]),
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.auto_awesome_rounded, size: 40),
                  SizedBox(height: 8),
                  Text('قل لـ AUREN ماذا تريد أن تشاهد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('مثال: عندي ساعة وعايز أنمي حماسي أو مسلسل خفيف.'),
                ]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _prompt, maxLines: 2,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  hintText: 'عندي ساعة وعايز شيء ممتع...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('المزاج', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _moods.map((v) => ChoiceChip(
                label: Text(v), selected: _mood == v,
                onSelected: (_) => setState(() => _mood = v),
              )).toList()),
              const SizedBox(height: 12),
              const Text('نوع المحتوى', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _types.map((v) => ChoiceChip(
                label: Text(v), selected: _type == v,
                onSelected: (_) => setState(() => _type = v),
              )).toList()),
              const SizedBox(height: 14),
              Text('الوقت: $_minutes دقيقة', style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(value: _minutes.toDouble(), min: 10, max: 240, divisions: 23,
                label: _minutes.toString(), onChanged: (v) => setState(() => _minutes = v.round())),
              FilledButton.icon(onPressed: () => _generate(source),
                icon: const Icon(Icons.auto_awesome_rounded), label: const Text('AUREN جهّز لي المشاهدة')),
              if (_plan.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('خطة مشاهدة • ${_plan.length} عناصر • $_minutes دقيقة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ..._plan.map((item) => Card(child: ListTile(
                  leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.movie_outlined))
                      : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                  title: Text(item.title),
                  subtitle: Text(item.type, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id))),
                ))),
              ],
            ],
          );
        },
      ),
    );
  }
}
