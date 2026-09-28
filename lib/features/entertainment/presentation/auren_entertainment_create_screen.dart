import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_entertainment_job_detail_screen.dart';
import 'auren_entertainment_library_screen.dart';

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
    'فيلم': Icons.local_movies_rounded,
    'بودكاست': Icons.podcasts_rounded,
    'عالم': Icons.public_rounded,
  };
  static const _moods = <String>['سينمائي','هادئ','حماسي','غامض','كوميدي','ملهم'];
  static const _lengths = <String>['قصير','متوسط','طويل'];

  String? _uid;
  bool _saving = false;
  String? _editingDraftId;
  String? _activeJobId;

  String get _idea => _promptController.text.trim();

  String _exampleFor(String mode) {
    switch (mode) {
      case 'أغنية':
        return 'أغنية عربية أصلية عن بداية رحلة جديدة.';
      case 'قصة':
        return 'قصة قصيرة عن شخص يكتشف مدينة غامضة.';
      case 'فيلم':
        return 'فيلم أصلي عن شاب من السودان يحاول بناء حياة جديدة بين مدينتين.';
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

  Future<void> _saveDraft() async {
    final uid = _uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    final idea = _idea.isEmpty ? _exampleFor(_mode) : _idea;
    try {
      if (_editingDraftId == null) {
        _editingDraftId = await EntertainmentRepository().saveEntertainmentDraft(uid, mode: _mode, mood: _mood, length: _length, idea: idea);
      } else {
        await EntertainmentRepository().updateEntertainmentDraft(uid, _editingDraftId!, mode: _mode, mood: _mood, length: _length, idea: idea);
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسودة.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المسودة.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startCreationJob() async {
    final uid = _uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    final idea = _idea.isEmpty ? _exampleFor(_mode) : _idea;
    try {
      final draftId = _editingDraftId ?? await EntertainmentRepository().saveEntertainmentDraft(uid, mode: _mode, mood: _mood, length: _length, idea: idea);
      _editingDraftId ??= draftId;
      _activeJobId = await EntertainmentRepository().createEntertainmentJob(uid, draftId: draftId, mode: _mode, mood: _mood, length: _length, idea: idea);
      try {
        if (_mode == 'مسلسل') {
          await EntertainmentRepository().generateSeriesBlueprint(_activeJobId!);
        } else if (_mode == 'فيلم') {
          await EntertainmentRepository().generateMovieBlueprint(_activeJobId!);
        } else if (_mode == 'أغنية') {
          await EntertainmentRepository().generateMusicBlueprint(_activeJobId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إنشاء مشروع $_mode وبدء مرحلة التخطيط بالذكاء الاصطناعي.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إنشاء مشروع $_mode، لكن التخطيط يحتاج إعداد مزود AI ثم إعادة المحاولة.')),
          );
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر بدء مهمة الإنتاج.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  Future<void> _create() async {
    if (_uid != null && !_saving) await _saveDraft();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: _buildPrompt())));
  }

  void _editDraft(Map<String, dynamic> draft) {
    setState(() {
      _editingDraftId = draft['id']?.toString();
      if (_modes.containsKey(draft['mode']?.toString())) _mode = draft['mode'].toString();
      if (_moods.contains(draft['mood']?.toString())) _mood = draft['mood'].toString();
      if (_lengths.contains(draft['length']?.toString())) _length = draft['length'].toString();
      _promptController.text = draft['idea']?.toString() ?? '';
    });
  }
  void _useExample() {
    _promptController.text = _exampleFor(_mode);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
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
        title: Text(_editingDraftId == null ? 'AUREN Create Studio' : 'تعديل المسودة'),
        actions: [
          IconButton(
            tooltip: 'مكتبة إنتاجاتك',
            icon: const Icon(Icons.video_library_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AurenEntertainmentLibraryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'إنشاء مهمة إنتاج',
            icon: const Icon(Icons.rocket_launch_rounded),
            onPressed: _saving ? null : _startCreationJob,
          ),
          IconButton(
            tooltip: 'ابدأ',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _saving ? null : _create,
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
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('حوّل الفكرة إلى مشروع',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          if (_uid != null) ...[
            const SizedBox(height: 18),
            _buildDrafts(context),
          ],
          if (_uid != null) ...[
            const SizedBox(height: 18),
            _buildJobs(context),
          ],
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

  Widget _buildDrafts(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: EntertainmentRepository().watchEntertainmentDrafts(_uid!),
      builder: (context, snapshot) {
        final drafts = snapshot.data ?? const <Map<String, dynamic>>[];
        if (drafts.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مسوداتك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...drafts.take(3).map((draft) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(_modes[draft['mode']?.toString()] ?? Icons.edit_note_rounded)),
                  title: Text('${draft['mode'] ?? 'مشروع'} • ${draft['mood'] ?? ''}'),
                  subtitle: Text(draft['idea']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => _editDraft(draft),
                  trailing: IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      await EntertainmentRepository().deleteEntertainmentDraft(_uid!, draft['id'].toString());
                      if (mounted && _editingDraftId == draft['id']?.toString()) setState(() => _editingDraftId = null);
                    },
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildJobs(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: EntertainmentRepository().watchEntertainmentCreationJobs(_uid!),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <Map<String, dynamic>>[];
        if (jobs.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مهام الإنتاج',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...jobs.take(3).map((job) {
                  final progress = (job['progress'] as num?)?.toInt() ?? 0;
                  final status = job['status']?.toString() ?? 'planning';
                  final plan = job['plan'] is List ? job['plan'] as List : const [];
                  final nextStep = plan.isNotEmpty ? plan.first.toString() : 'الخطة قيد التجهيز';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Icon(
                        status == 'failed'
                            ? Icons.error_outline_rounded
                            : status == 'ready'
                                ? Icons.check_rounded
                                : Icons.movie_filter_rounded,
                      ),
                    ),
                    title: Text('${job['mode'] ?? 'مشروع'} • ${status}'),
                    subtitle: Text(
                      'التقدم ${progress}% • ${job['provider'] ?? 'auren_ai'}\n${nextStep}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(value: progress / 100),
                    ),
                    onTap: () {
                      final id = job['id']?.toString();
                      if (id == null || id.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AurenEntertainmentJobDetailScreen(jobId: id),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
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
