import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_audio_player_screen.dart';

class AurenMusicConciergeScreen extends StatefulWidget {
  final List<AurenEntertainmentItem> source;
  const AurenMusicConciergeScreen({super.key, required this.source});
  @override
  State<AurenMusicConciergeScreen> createState() => _AurenMusicConciergeScreenState();
}

class _AurenMusicConciergeScreenState extends State<AurenMusicConciergeScreen> {
  final prompt = TextEditingController();
  String activity = 'تلقائي';
  String mood = 'الكل';
  int minutes = 45;
  String contextMode = 'تلقائي';
  String contentMode = 'موسيقى';
  Map<String, Map<String, dynamic>> signals = const {};
  List<AurenEntertainmentItem> plan = const [];

  static const activities = ['تلقائي', 'تمرين', 'دراسة', 'سفر', 'نوم', 'استرخاء', 'حفلة'];
  static const moods = ['الكل', 'هادئ', 'حماس', 'تركيز', 'سفر', 'تسلية'];
  static const contexts = ['تلقائي', 'صباح', 'ليل', 'عمل', 'رحلة', 'استرخاء'];
  static const contentModes = ['موسيقى', 'راديو', 'بودكاست', 'أي صوت'];

  @override
  void initState() {
    super.initState();
    prompt.addListener(parsePrompt);
  }

  @override
  void dispose() {
    prompt.removeListener(parsePrompt);
    prompt.dispose();
    super.dispose();
  }

  void parsePrompt() {
    final text = prompt.text.toLowerCase();
    int? parsed;
    final h = RegExp(r'(\d+(?:\.\d+)?)\s*(?:ساعة|ساعات|hour|hours|hr|hrs)').firstMatch(text);
    final m = RegExp(r'(\d+)\s*(?:دقيقة|دقائق|minute|minutes|min|mins)').firstMatch(text);
    if (h != null) parsed = ((double.tryParse(h.group(1)!) ?? 1) * 60).round();
    if (h == null && m != null) parsed = int.tryParse(m.group(1)!);
    if (parsed != null) {
      final next = parsed!.clamp(10, 240);
      if (next != minutes && mounted) setState(() => minutes = next);
    }

    const moodKeys = <String, List<String>>{
      'هادئ': ['هادئ', 'calm', 'relax', 'chill', 'quiet'],
      'حماس': ['حماس', 'energetic', 'energy', 'power'],
      'تركيز': ['تركيز', 'focus', 'study'],
      'سفر': ['سفر', 'رحلة', 'travel', 'trip'],
      'تسلية': ['تسلية', 'fun', 'entertainment'],
    };
    for (final e in moodKeys.entries) {
      if (e.value.any(text.contains) && mood != e.key && mounted) {
        setState(() => mood = e.key);
        break;
      }
    }

    const contextKeys = <String, List<String>>{
      'صباح': ['صباح', 'morning'], 'ليل': ['ليل', 'night'], 'عمل': ['عمل', 'work'],
      'رحلة': ['رحلة', 'سفر', 'travel', 'trip'], 'استرخاء': ['استرخاء', 'relax', 'calm'],
    };
    for (final e in contextKeys.entries) {
      if (e.value.any(text.contains) && contextMode != e.key && mounted) {
        setState(() => contextMode = e.key);
        break;
      }
    }

    const contentKeys = <String, List<String>>{
      'بودكاست': ['بودكاست', 'podcast'], 'راديو': ['راديو', 'radio'], 'موسيقى': ['موسيقى', 'music', 'song'],
    };
    for (final e in contentKeys.entries) {
      if (e.value.any(text.contains) && contentMode != e.key && mounted) {
        setState(() => contentMode = e.key);
        break;
      }
    }

    const keys = <String, List<String>>{
      'تمرين': ['تمرين', 'رياضة', 'gym', 'workout', 'exercise'],
      'دراسة': ['دراسة', 'مذاكرة', 'تركيز', 'study', 'focus'],
      'سفر': ['سفر', 'رحلة', 'travel', 'trip'],
      'نوم': ['نوم', 'sleep'],
      'استرخاء': ['استرخاء', 'هادئ', 'relax', 'calm', 'chill'],
      'حفلة': ['حفلة', 'رقص', 'party', 'dance'],
    };
    for (final e in keys.entries) {
      if (e.value.any(text.contains) && activity != e.key && mounted) {
        setState(() => activity = e.key);
        break;
      }
    }
  }

  List<AurenEntertainmentItem> buildPlan() {
    final query = prompt.text.trim().toLowerCase();
    final candidates = widget.source.where((item) {
      if (item.mediaUrl.isEmpty) return false;
      if (query.isEmpty) return true;
      final text = (item.title + ' ' + item.description).toLowerCase();
      final words = query.split(RegExp(r'\s+')).where((x) => x.length > 2);
      return words.isEmpty || words.any(text.contains);
    }).toList();

    const hints = <String, List<String>>{
      'تمرين': ['workout', 'gym', 'exercise', 'تمرين', 'رياضة'],
      'دراسة': ['study', 'focus', 'دراسة', 'تركيز'],
      'سفر': ['travel', 'trip', 'سفر', 'رحلة'],
      'نوم': ['sleep', 'night', 'نوم', 'ليل'],
      'استرخاء': ['relax', 'calm', 'chill', 'استرخاء', 'هادئ'],
      'حفلة': ['party', 'dance', 'حفلة', 'رقص'],
    };
    candidates.sort((a, b) {
      double score(AurenEntertainmentItem item) {
        final text = (item.title + ' ' + item.description).toLowerCase();
        var value = item.title.length * .05 + item.description.length * .01;
        if (activity != 'تلقائي' && (hints[activity] ?? const []).any(text.contains)) value += 20;
        if (mood != 'الكل' && text.contains(mood.toLowerCase())) value += 12;
        if (contextMode != 'تلقائي' && text.contains(contextMode.toLowerCase())) value += 8;
        if (contentMode != 'أي صوت' && item.type.toLowerCase().contains(contentMode.toLowerCase())) value += 10;
        final words = prompt.text.toLowerCase().split(RegExp(r'\\s+')).where((x) => x.length > 2);
        value += words.where(text.contains).length * 2;
        final signal = signals[item.id];
        if (signal != null) {
          value += ((signal['watchSeconds'] as num?)?.toDouble() ?? 0) * .02;
          value += ((signal['plays'] as num?)?.toDouble() ?? 0) * .5;
          value += ((signal['likes'] as num?)?.toDouble() ?? 0) * 5;
          value += ((signal['saves'] as num?)?.toDouble() ?? 0) * 3;
          value += ((signal['completions'] as num?)?.toDouble() ?? 0) * 2;
          value -= ((signal['skips'] as num?)?.toDouble() ?? 0) * 2;
        }
        if (AurenMusicPlayerController.instance.history.any((x) => x.id == item.id)) value += 4;
        return value;
      }
      return score(b).compareTo(score(a));
    });
    return candidates;
  }

  String _sessionShape() {
    switch (activity) {
      case 'تمرين': return 'إحماء → تصاعد → ذروة → تعافٍ';
      case 'دراسة': return 'تهيئة → تركيز ثابت → تنويع خفيف → نهاية هادئة';
      case 'سفر': return 'بداية → تنويع → مفضلات → خاتمة هادئة';
      case 'نوم': return 'هدوء تدريجي → استقرار → خاتمة ناعمة';
      case 'حفلة': return 'إحماء → تصاعد → ذروة → تنويع';
      case 'استرخاء': return 'هدوء → استرخاء عميق → خاتمة لطيفة';
      default: return 'بداية → قلب الجلسة → تنويع → خاتمة';
    }
  }

  List<AurenEntertainmentItem> _buildSession(List<AurenEntertainmentItem> sorted) {
    final target = sorted.isEmpty ? 0 : (minutes / 3).ceil().clamp(1, sorted.length);
    if (target <= 1) return sorted.take(target).toList();
    final used = <String>{};
    final result = <AurenEntertainmentItem>[];

    bool calm(AurenEntertainmentItem x) {
      final t = (x.title + ' ' + x.description).toLowerCase();
      return ['calm', 'chill', 'relax', 'quiet', 'soft', 'sleep', 'هادئ', 'استرخاء', 'نوم'].any(t.contains);
    }
    bool energetic(AurenEntertainmentItem x) {
      final t = (x.title + ' ' + x.description).toLowerCase();
      return ['energy', 'energetic', 'workout', 'gym', 'party', 'dance', 'power', 'حماس', 'تمرين', 'حفلة'].any(t.contains);
    }
    AurenEntertainmentItem? takeWhere(bool Function(AurenEntertainmentItem) test) {
      for (final item in sorted) {
        if (!used.contains(item.id) && test(item)) {
          used.add(item.id); result.add(item); return item;
        }
      }
      return null;
    }

    final intro = (target * .2).floor().clamp(1, target - 1);
    final core = (target * .5).floor().clamp(1, target - intro);
    final variety = (target * .2).floor().clamp(0, target - intro - core);
    final outro = target - intro - core - variety;

    for (var i = 0; i < intro; i++) {
      if (activity == 'تمرين' || activity == 'حفلة') takeWhere((x) => !energetic(x));
      else takeWhere(calm);
    }
    for (var i = 0; i < core; i++) {
      var picked = false;
      for (final item in sorted) {
        if (!used.contains(item.id) && !calm(item)) {
          used.add(item.id); result.add(item); picked = true; break;
        }
      }
      if (!picked) takeWhere((_) => true);
    }
    final creators = <String>{};
    for (var i = 0; i < variety; i++) {
      final picked = takeWhere((x) => x.creatorId.isNotEmpty && !creators.contains(x.creatorId));
      if (picked != null) creators.add(picked.creatorId); else takeWhere((_) => true);
    }
    for (var i = 0; i < outro; i++) takeWhere(calm);
    for (final item in sorted) {
      if (result.length >= target) break;
      if (used.add(item.id)) result.add(item);
    }
    return result.take(target).toList();
  }

  Future<void> generate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        signals = await EntertainmentRepository().getMusicSignals(uid);
      } catch (_) {}
    }
    if (!mounted) return;
    final sorted = buildPlan();
    final session = _buildSession(sorted);
    setState(() => plan = session);
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم أجد مقاطع مناسبة. جرّب نشاطًا أو مدة مختلفة.')),
      );
    }
  }

  Future<void> addAll() async {
    final controller = AurenMusicPlayerController.instance;
    var added = 0;
    for (final item in plan) {
      if (!controller.queue.any((q) => q.id == item.id)) {
        await controller.addToQueue(item);
        added++;
      }
    }
    if (!mounted) return;
    if (added > 0) {
      controller.startAdaptiveSession(
        candidates: plan,
        activity: activity,
        mood: mood,
        contextMode: contextMode,
        contentMode: contentMode,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        added > 0
          ? 'AUREN أضاف ' + added.toString() + ' مقاطع • والتكييف التلقائي للجلسة مفعّل 🎵'
          : 'المقاطع موجودة بالفعل في Queue.',
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimated = plan.length * 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Music Concierge'),
        actions: [
          if (plan.isNotEmpty)
            IconButton(icon: const Icon(Icons.queue_music_rounded), onPressed: addAll),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.tertiaryContainer,
              ]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 40),
                SizedBox(height: 8),
                Text('قل لـ AUREN ماذا تريد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('مثال: أنا مسافر ساعتين وعايز موسيقى هادئة.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: prompt,
            maxLines: 2,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              hintText: 'أنا مسافر ساعتين وعايز موسيقى هادئة...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('النشاط', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activities.map((v) => ChoiceChip(
              label: Text(v),
              selected: activity == v,
              onSelected: (_) => setState(() => activity = v),
            )).toList(),
          ),
          const SizedBox(height: 12),
          const Text('السياق', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: contexts.map((v) => ChoiceChip(
            label: Text(v), selected: contextMode == v,
            onSelected: (_) => setState(() => contextMode = v),
          )).toList()),
          const SizedBox(height: 12),
          const Text('نوع المحتوى', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: contentModes.map((v) => ChoiceChip(
            label: Text(v), selected: contentMode == v,
            onSelected: (_) => setState(() => contentMode = v),
          )).toList()),
          const SizedBox(height: 12),
          const Text('المزاج', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((v) => ChoiceChip(
              label: Text(v),
              selected: mood == v,
              onSelected: (_) => setState(() => mood = v),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('المدة: ' + minutes.toString() + ' دقيقة', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: minutes.toDouble(),
            min: 10,
            max: 240,
            divisions: 23,
            label: minutes.toString(),
            onChanged: (v) => setState(() => minutes = v.round()),
          ),
          Wrap(
            spacing: 8,
            children: [20, 30, 45, 60, 120].map((v) => ActionChip(
              label: Text(v >= 60 ? (v ~/ 60).toString() + ' ساعة' : v.toString() + ' دقيقة'),
              onPressed: () => setState(() => minutes = v),
            )).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: generate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('AUREN جهّزها لي'),
          ),
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('الجلسة: ' + plan.length.toString() + ' مقاطع • حوالي ' + estimated.toString() + ' دقيقة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('بنية الجلسة: ' + _sessionShape(), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...plan.map((item) => Card(
              child: ListTile(
                leading: item.imageUrl.isEmpty
                    ? const CircleAvatar(child: Icon(Icons.music_note))
                    : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                title: Text(item.title),
                subtitle: Text(item.description.isEmpty ? item.type : item.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AurenAudioPlayerScreen(item: item),
                )),
                trailing: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => AurenMusicPlayerController.instance.addToQueue(item),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
