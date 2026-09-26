import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
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
  List<AurenEntertainmentItem> plan = const [];

  static const activities = ['تلقائي', 'تمرين', 'دراسة', 'سفر', 'نوم', 'استرخاء', 'حفلة'];
  static const moods = ['الكل', 'هادئ', 'حماس', 'تركيز', 'سفر', 'تسلية'];

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
        if (AurenMusicPlayerController.instance.history.any((x) => x.id == item.id)) value += 4;
        return value;
      }
      return score(b).compareTo(score(a));
    });
    return candidates;
  }

  void generate() {
    final sorted = buildPlan();
    final count = sorted.isEmpty ? 0 : (minutes / 3).ceil().clamp(1, sorted.length);
    setState(() => plan = sorted.take(count).toList());
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AUREN أضاف ' + added.toString() + ' مقاطع إلى Queue • حوالي ' + minutes.toString() + ' دقيقة 🎵')),
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
            Text('الخطة: ' + plan.length.toString() + ' مقاطع • حوالي ' + estimated.toString() + ' دقيقة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
