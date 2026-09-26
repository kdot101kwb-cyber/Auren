import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

class AurenEntertainmentCreateScreen extends StatefulWidget {
  const AurenEntertainmentCreateScreen({super.key});
  @override
  State<AurenEntertainmentCreateScreen> createState() =>
      _AurenEntertainmentCreateScreenState();
}

class _AurenEntertainmentCreateScreenState
    extends State<AurenEntertainmentCreateScreen> {
  final _promptController = TextEditingController();
  String _mode = 'أغنية';
  String _mood = 'سينمائي';
  String _length = 'متوسط';

  static const _modes = <String, IconData>{
    'أغنية': Icons.music_note_rounded,
    'قصة': Icons.auto_stories_rounded,
    'فيديو': Icons.movie_creation_rounded,
    'بودكاست': Icons.podcasts_rounded,
    'عالم': Icons.public_rounded,
  };
  static const _moods = <String>['سينمائي','هادئ','حماسي','غامض','كوميدي','ملهم'];
  static const _lengths = <String>['قصير','متوسط','طويل'];

  String get _idea => _promptController.text.trim();

  String _exampleFor(String mode) {
    switch (mode) {
      case 'أغنية':
        return 'أغنية عربية أصلية عن بداية رحلة جديدة.';
      case 'قصة':
        return 'قصة قصيرة عن شخص يكتشف مدينة غامضة.';
      case 'فيديو':
        return 'فيديو قصير يحكي فكرة ملهمة بصرياً.';
      case 'بودكاست':
        return 'حلقة عن قصة نجاح شاب بدأ من الصفر.';
      default:
        return 'عالم تفاعلي صغير فيه أماكن وشخصيات ومهام.';
    }
  }

  String _buildPrompt() {
    final idea = _idea.isEmpty ? _exampleFor(_mode) : _idea;
    return '''
أنت AUREN Entertainment Creator AI.
حوّل المشروع التالي إلى إنتاج ترفيهي أصلي قابل للتنفيذ داخل AUREN.

النوع: $_mode
الطابع: $_mood
الطول: $_length
الفكرة: $idea

أريد:
1. Concept واضح وعنواناً مناسباً.
2. وصفاً قصيراً وتجربة المستخدم المستهدفة.
3. الهيكل الكامل للمحتوى حسب النوع.
4. خطة إنتاج على مراحل.
5. الأصول المطلوبة: نص، صوت، موسيقى، صور، فيديو، شخصيات أو مشاهد عند الحاجة.
6. تحديد ما يمكن للذكاء الاصطناعي تنفيذه وما يحتاج أداة أو مزوداً خارجياً.
7. خطوات تنفيذ عملية داخل AUREN.
8. اقتراح نسخة MVP صغيرة يمكن إنتاجها أولاً.
9. الحفاظ على الأصالة وحقوق الملكية وعدم تقليد صوت أو هوية فنان حقيقي دون إذن.
''';
  }

  void _create() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: _buildPrompt()),
      ),
    );
  }

  void _useExample() {
    _promptController.text = _exampleFor(_mode);
    setState(() {});
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Create Studio'),
        actions: [
          IconButton(
            tooltip: 'ابدأ',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _create,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _hero(context),
          const SizedBox(height: 20),
          const Text('ماذا تريد أن تصنع؟',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _modes.entries.map((e) {
              return ChoiceChip(
                avatar: Icon(e.value, size: 18),
                label: Text(e.key),
                selected: _mode == e.key,
                onSelected: (_) => setState(() => _mode = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const Text('الطابع',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moods.map((m) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          const Text('الطول',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          SegmentedButton<String>(
            segments: _lengths
                .map((v) => ButtonSegment<String>(value: v, label: Text(v)))
                .toList(),
            selected: {_length},
            onSelectionChanged: (v) => setState(() => _length = v.first),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _promptController,
            minLines: 5,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'فكرتك',
              hintText: _exampleFor(_mode),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              suffixIcon: IconButton(
                tooltip: 'استخدم مثالاً',
                icon: const Icon(Icons.lightbulb_outline_rounded),
                onPressed: _useExample,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('AUREN يفهم مشروعك',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Text(_idea.isEmpty ? 'مثال جاهز' : 'جاهز',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('$_mode • $_mood • $_length'),
                  const SizedBox(height: 6),
                  Text(
                    _idea.isEmpty ? _exampleFor(_mode) : _idea,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: const [
                      Chip(label: Text('Concept')),
                      Chip(label: Text('خطة إنتاج')),
                      Chip(label: Text('AI Assets')),
                      Chip(label: Text('MVP')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('حوّل الفكرة إلى مشروع',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AUREN يبني أولاً الـConcept وخطة الإنتاج عبر AI. ربط مولدات الصوت والفيديو والعوالم الفعلية يأتي كطبقة إنتاج لاحقة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 34),
          SizedBox(height: 10),
          Text('من فكرة إلى تجربة',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text(
            'اختار النوع والطابع والطول، اكتب فكرتك، وشوف فوراً كيف فهمها AUREN قبل بدء الإنشاء.',
          ),
        ],
      ),
    );
  }
}
