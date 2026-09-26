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
  Map<String, Map<String, dynamic>> _history = const {};
  Map<String, double> _typeAffinity = const {};
  Map<String, double> _creatorAffinity = const {};
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
    score += (_typeAffinity[item.type] ?? 0).clamp(-8, 12);
    if (item.creatorId.isNotEmpty) score += (_creatorAffinity[item.creatorId] ?? 0).clamp(-6, 10);

    final signal = _signals[item.id];
    if (signal != null) {
      score += ((signal['watchSeconds'] as num?)?.toDouble() ?? 0) * .01;
      score += ((signal['views'] as num?)?.toDouble() ?? 0) * 1.5;
      score += ((signal['likes'] as num?)?.toDouble() ?? 0).clamp(-2, 4) * 2;
      score += ((signal['saves'] as num?)?.toDouble() ?? 0).clamp(-2, 4) * 2;
      score += ((signal['completions'] as num?)?.toDouble() ?? 0) * 5;
      score -= ((signal['skips'] as num?)?.toDouble() ?? 0) * 3;

      // Explicit feedback beats passive viewing: a like/save is a stronger
      // preference signal, while repeated skips suppress the item.
      if (signal['mood'] is String &&
          _mood != 'الكل' &&
          signal['mood'] == _mood) {
        score += 4;
      }
    } else {
      score += 5; // discovery boost for content with no prior signal
    }
    final history = _history[item.id];
    if (history != null) {
      final progress = ((history['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
      final completed = history['completed'] == true;
      // Prefer unfinished content for "continue/discover" plans, while still
      // allowing completed items back in when the user explicitly searches for them.
      if (progress > 0 && !completed) score += 10 + progress * 8;
      if (completed && _prompt.text.trim().isEmpty) score -= 7;
      score += ((history['views'] as num?)?.toDouble() ?? 0).clamp(0, 3) * 0.5;
    }
    return score;
  }

  void _buildAffinities(List<AurenEntertainmentItem> source) {
    final typeScores = <String, double>{};
    final creatorScores = <String, double>{};
    AurenEntertainmentItem? findItem(String id) {
      for (final item in source) {
        if (item.id == id) return item;
      }
      return null;
    }

    for (final entry in _signals.entries) {
      final item = findItem(entry.key);
      if (item == null) continue;
      final s = entry.value;
      final value =
          ((s['watchSeconds'] as num?)?.toDouble() ?? 0) * .005 +
          ((s['views'] as num?)?.toDouble() ?? 0) * .6 +
          ((s['likes'] as num?)?.toDouble() ?? 0) * 3 +
          ((s['saves'] as num?)?.toDouble() ?? 0) * 2 +
          ((s['completions'] as num?)?.toDouble() ?? 0) * 4 -
          ((s['skips'] as num?)?.toDouble() ?? 0) * 3;
      typeScores[item.type] = (typeScores[item.type] ?? 0) + value;
      if (item.creatorId.isNotEmpty) {
        creatorScores[item.creatorId] = (creatorScores[item.creatorId] ?? 0) + value;
      }
    }

    for (final entry in _history.entries) {
      final item = findItem(entry.key);
      if (item == null) continue;
      final progress = ((entry.value['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
      final value = entry.value['completed'] == true ? 2.0 : progress * 4;
      typeScores[item.type] = (typeScores[item.type] ?? 0) + value;
      if (item.creatorId.isNotEmpty) {
        creatorScores[item.creatorId] = (creatorScores[item.creatorId] ?? 0) + value;
      }
    }

    double normalize(double value) => (value / 4).clamp(-8.0, 12.0);
    _typeAffinity = {for (final e in typeScores.entries) e.key: normalize(e.value)};
    _creatorAffinity = {for (final e in creatorScores.entries) e.key: normalize(e.value)};
  }

  double _explorationBoost(AurenEntertainmentItem item) {
    if (_history.containsKey(item.id) || _signals.containsKey(item.id)) return 0;
    final typeKnown = _typeAffinity.containsKey(item.type);
    // Novelty stays a bounded signal so it cannot overpower explicit preferences.
    return typeKnown ? 2.5 : 5.0;
  }

  double _recencyBoost(AurenEntertainmentItem item) {
    final history = _history[item.id];
    if (history == null) return 0;
    final raw = history['lastWatchedAt'];
    if (raw is Timestamp) {
      final days = DateTime.now().difference(raw.toDate()).inDays;
      if (days <= 1) return 3;
      if (days <= 7) return 2;
      if (days <= 30) return 1;
    }
    return 0;
  }

  List<AurenEntertainmentItem> _buildPlan(List<AurenEntertainmentItem> items) {
    final usable = items
        .where((x) => x.mediaUrl.isNotEmpty || x.imageUrl.isNotEmpty)
        .toList();
    for (final item in usable) {
      // Freshness is intentionally a small signal, so it never overwhelms
      // explicit user preferences.
      if (_history.containsKey(item.id)) {
        // Applied below through a stable per-item score adjustment.
      }
    }

    // Discovery-first: reserve part of the plan for never-watched items,
    // while keeping the strongest personalized items in the remaining slots.
    final neverWatched = usable.where((x) => !_history.containsKey(x.id)).toList();
    final personalized = usable.where((x) => _history.containsKey(x.id)).toList();
    double rankedScore(AurenEntertainmentItem item) =>
        _score(item) + _recencyBoost(item) + _explorationBoost(item);

    // Build a diversified candidate pool first. This prevents the same type
    // from filling the whole plan even when its raw recommendation score is high.
    final ranked = [...usable]
      ..sort((a, b) => rankedScore(b).compareTo(rankedScore(a)));
    final typeCounts = <String, int>{};
    final diverse = <AurenEntertainmentItem>[];
    for (final item in ranked) {
      final count = typeCounts[item.type] ?? 0;
      if (count >= 2 && ranked.length > target * 2) continue;
      diverse.add(item);
      typeCounts[item.type] = count + 1;
    }
    final diversifiedNeverWatched =
        diverse.where((x) => !_history.containsKey(x.id)).toList();
    final diversifiedPersonalized =
        diverse.where((x) => _history.containsKey(x.id)).toList();
    diversifiedNeverWatched.sort(
      (a, b) => rankedScore(b).compareTo(rankedScore(a)),
    );
    diversifiedPersonalized.sort(
      (a, b) => rankedScore(b).compareTo(rankedScore(a)),
    );
    if (usable.isEmpty) return const [];
    final target = (_minutes / 30).ceil().clamp(1, 8);
    final result = <AurenEntertainmentItem>[];
    final creators = <String>{};
    final discoveryTarget = target >= 3 ? (target * 0.4).ceil() : target;

    void addFrom(List<AurenEntertainmentItem> pool, {bool discovery = false}) {
      for (final item in pool) {
        if (result.length >= target) break;
        if (discovery && result.length >= discoveryTarget) break;
        if (item.creatorId.isNotEmpty && creators.contains(item.creatorId)) continue;
        result.add(item);
        if (item.creatorId.isNotEmpty) creators.add(item.creatorId);
      }
    }

    addFrom(diversifiedNeverWatched, discovery: true);
    addFrom(diversifiedPersonalized);
    addFrom(diversifiedNeverWatched);
    addFrom(usable);
    return result;
  }

  Future<void> _generate(List<AurenEntertainmentItem> source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final repo = EntertainmentRepository();
        final snap = await repo.db.collection('users').doc(uid)
            .collection('entertainmentSignals').get();
        _signals = {for (final d in snap.docs) d.id: d.data()};
        final history = await repo.db.collection('users').doc(uid)
            .collection('watchHistory').limit(100).get();
        _history = {for (final d in history.docs) d.id: d.data()};
      } catch (_) {}
    }
    _buildAffinities(source);
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _plan = _buildPlan(source)),
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('اكتشف Mix مختلف'),
                ),
              ],
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
