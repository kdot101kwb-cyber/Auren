import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local-first production planner. Media generation requires a connected engine.
class CreativeProductionWorkflowScreen extends StatefulWidget {
  const CreativeProductionWorkflowScreen({super.key});

  @override
  State<CreativeProductionWorkflowScreen> createState() => _CreativeProductionWorkflowScreenState();
}

class _CreativeProductionWorkflowScreenState extends State<CreativeProductionWorkflowScreen> {
  static const _key = 'nova_creative_workflow_v1';
  final _title = TextEditingController();
  final _idea = TextEditingController();
  final _audience = TextEditingController();
  String _type = 'كرتون / قصة';
  String _language = 'العربية';
  String _format = '9:16 عمودي';
  bool _busy = false;
  String _plan = '';
  final Map<String, bool> _stages = {
    'كتابة السيناريو وتقسيم المشاهد': true,
    'تصميم الشخصية والمظهر': true,
    'إنشاء الصور والخلفيات': true,
    'تسجيل أو توليد الصوت': true,
    'تحريك الشخصية ومزامنة الشفاه': true,
    'المونتاج والترجمة والمؤثرات': true,
    'مراجعة الجودة والحقوق': true,
    'تجهيز نسخة للنشر': true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _idea.dispose();
    _audience.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _title.text = p.getString('$_key.title') ?? '';
      _idea.text = p.getString('$_key.idea') ?? '';
      _audience.text = p.getString('$_key.audience') ?? '';
      _type = p.getString('$_key.type') ?? _type;
      _language = p.getString('$_key.language') ?? _language;
      _format = p.getString('$_key.format') ?? _format;
      _plan = p.getString('$_key.plan') ?? '';
      for (final stage in _stages.keys) {
        _stages[stage] = p.getBool('$_key.stage.$stage') ?? true;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('$_key.title', _title.text.trim());
      await p.setString('$_key.idea', _idea.text.trim());
      await p.setString('$_key.audience', _audience.text.trim());
      await p.setString('$_key.type', _type);
      await p.setString('$_key.language', _language);
      await p.setString('$_key.format', _format);
      await p.setString('$_key.plan', _plan);
      for (final e in _stages.entries) {
        await p.setBool('$_key.stage.${e.key}', e.value);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسودة على هذا الجهاز.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المسودة محلياً.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _makePlan() async {
    if (_idea.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب وصف الفكرة أولاً.')));
      return;
    }
    final stages = _stages.entries.where((e) => e.value).map((e) => '• ${e.key}').join('\n');
    setState(() {
      _plan = '''
خطة إنتاج NOVA
المشروع: ${_title.text.trim().isEmpty ? 'مشروع جديد' : _title.text.trim()}
النوع: $_type | اللغة: $_language | المقاس: $_format
الجمهور: ${_audience.text.trim().isEmpty ? 'يحدد لاحقاً' : _audience.text.trim()}

الفكرة:
${_idea.text.trim()}

مراحل التنفيذ:
$stages

التوجيه: ابدأ بالسيناريو ولوحة المشاهد، ثم الأصول البصرية والصوت، فالتحريك والمونتاج. عند غياب محرك توليد، احتفظ بالخطة والمواد اليدوية ولا تدّعِ إنشاء ملفات لم تُنتج فعلياً.
'''.trim();
    });
    await _save();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الأداة.')));
  }

  Widget _heading(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Row(children: [Icon(icon), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)))]),
  );

  Widget _tool(String title, String url, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: OutlinedButton.icon(
      onPressed: () => _open(url),
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(alignment: Alignment.centerRight, padding: const EdgeInsets.all(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final done = _stages.values.where((v) => v).length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('خط إنتاج NOVA الإبداعي')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF49317C), Color(0xFF202039)]), borderRadius: BorderRadius.circular(20)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.movie_filter_outlined, color: Color(0xFFB9A9FF), size: 30),
              SizedBox(height: 8),
              Text('من الفكرة إلى خطة إنتاج', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('خطط للكرتون والشخصيات والصور والصوت والفيديو. المسودة تحفظ محلياً ولا ترسل فكرتك إلى خدمة خارجية.'),
            ]),
          ),
          _heading('1. تفاصيل المشروع', Icons.edit_note),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'نوع المحتوى', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'فيديو قصير', child: Text('فيديو قصير')),
              DropdownMenuItem(value: 'كرتون / قصة', child: Text('كرتون / قصة')),
              DropdownMenuItem(value: 'صورة / إعلان', child: Text('صورة / إعلان')),
              DropdownMenuItem(value: 'شخصية ناطقة', child: Text('شخصية ناطقة')),
              DropdownMenuItem(value: 'موسيقى / مؤثرات', child: Text('موسيقى / مؤثرات')),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 10),
          TextField(controller: _audience, decoration: const InputDecoration(labelText: 'الجمهور المستهدف (اختياري)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(labelText: 'لغة المحتوى', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'العربية', child: Text('العربية')),
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'العربية + English', child: Text('العربية + English')),
              DropdownMenuItem(value: 'متعدد اللغات', child: Text('متعدد اللغات')),
            ],
            onChanged: (v) => setState(() => _language = v ?? _language),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _format,
            decoration: const InputDecoration(labelText: 'مقاس المخرجات', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: '9:16 عمودي', child: Text('9:16 عمودي — Shorts / Reels')),
              DropdownMenuItem(value: '16:9 أفقي', child: Text('16:9 أفقي — YouTube')),
              DropdownMenuItem(value: '1:1 مربع', child: Text('1:1 مربع — منشور')),
              DropdownMenuItem(value: '4:5 عمودي', child: Text('4:5 عمودي — صور اجتماعية')),
            ],
            onChanged: (v) => setState(() => _format = v ?? _format),
          ),
          const SizedBox(height: 10),
          TextField(controller: _idea, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'وصف الفكرة والمشهد', hintText: 'صف الشخصية، الأسلوب، الحوار، الخلفية، الجو العام والرسالة...', alignLabelWithHint: true, border: OutlineInputBorder())),
          _heading('2. مراحل الإنتاج', Icons.account_tree_outlined),
          LinearProgressIndicator(value: done / _stages.length),
          const SizedBox(height: 5),
          Text('$done من ${_stages.length} مراحل محددة'),
          for (final e in _stages.entries)
            CheckboxListTile(value: e.value, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: Text(e.key), onChanged: (v) => setState(() => _stages[e.key] = v ?? false)),
          _heading('3. أدوات الإنتاج', Icons.extension_outlined),
          const Text('تفتح الروابط الرسمية. الربط الفعلي داخل NOVA لم يُفعّل بعد.'),
          _tool('ComfyUI — الصور وسير العمل', 'https://github.com/Comfy-Org/ComfyUI', Icons.image_outlined),
          _tool('OpenToonz — صناعة الكرتون', 'https://opentoonz.github.io/e/', Icons.animation_outlined),
          _tool('SadTalker — شخصية ناطقة', 'https://github.com/OpenTalker/SadTalker', Icons.face_retouching_natural_outlined),
          _tool('F5-TTS — تحويل النص إلى صوت', 'https://github.com/SWivid/F5-TTS', Icons.record_voice_over_outlined),
          _tool('MoviePy — المونتاج', 'https://github.com/Zulko/moviepy', Icons.movie_creation_outlined),
          _heading('4. الخطة الناتجة', Icons.assignment_turned_in_outlined),
          FilledButton.icon(onPressed: _busy ? null : _makePlan, icon: const Icon(Icons.playlist_add_check), label: Text(_busy ? 'جارٍ الحفظ...' : 'إنشاء خطة الإنتاج وحفظها')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('حفظ المسودة')),
          if (_plan.isNotEmpty) ...[const SizedBox(height: 12), SelectableText(_plan)],
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('الشفافية: هذه الشاشة تنظّم المشروع وتنتج خطة نصية محلية فقط. توليد الصور والصوت والفيديو يتطلب محركاً متصلاً ونماذج مناسبة واختباراً فعلياً.'))),
        ]),
      ),
    );
  }
}
