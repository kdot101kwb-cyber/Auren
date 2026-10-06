import 'package:flutter/material.dart';
import '../../../services/talent/music_audio_recorder.dart';

class AurenMusicAudioLab extends StatefulWidget {
  const AurenMusicAudioLab({super.key});
  @override State<AurenMusicAudioLab> createState() => _AurenMusicAudioLabState();
}

class _AurenMusicAudioLabState extends State<AurenMusicAudioLab> {
  final _recorder = AurenMusicAudioRecorder();
  bool _recording = false, _analyzing = false;
  String? _path, _error;
  AurenMusicAudioAnalysis? _result;

  @override void dispose() { _recorder.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    setState(() => _error = null);
    if (_recording) {
      final path = await _recorder.stopRecording();
      if (!mounted) return;
      setState(() { _recording = false; _path = path; });
      if (path != null) await _analyze(path);
      return;
    }
    try {
      if (!await _recorder.requestPermission()) { setState(() => _error = 'لم يتم السماح باستخدام الميكروفون.'); return; }
      final path = await _recorder.startWavRecording();
      if (!mounted) return;
      if (path == null) { setState(() => _error = 'تعذر بدء التسجيل.'); return; }
      setState(() { _recording = true; _path = null; _result = null; });
    } catch (e) { if (mounted) setState(() => _error = 'تعذر بدء التسجيل: ' + e.toString()); }
  }

  Future<void> _analyze(String path) async {
    setState(() => _analyzing = true);
    try {
      final result = await _recorder.analyzeWav(path);
      if (!mounted) return;
      setState(() => _result = result);
      if (result == null) setState(() => _error = 'تعذر تحليل ملف الصوت.');
    } catch (e) { if (mounted) setState(() => _error = 'حدث خطأ أثناء التحليل: ' + e.toString()); }
    finally { if (mounted) setState(() => _analyzing = false); }
  }

  @override Widget build(BuildContext context) {
    final r = _result;
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🎙️ Music Audio Lab', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('سجّل صوتك ثم احصل على قراءة أولية للتردد والنوتة والانحراف وقوة الإشارة على الجهاز.'),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _analyzing ? null : _toggle, icon: Icon(_recording ? Icons.stop : Icons.mic), label: Text(_recording ? 'إيقاف وتحليل' : 'ابدأ التسجيل')),
      if (_recording) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      if (_analyzing) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
      if (r != null) ...[
        const Divider(height: 24),
        const Text('نتيجة التحليل', style: TextStyle(fontWeight: FontWeight.w900)),
        _metric('النوتة', r.note ?? 'غير واضحة'),
        _metric('التردد', r.frequencyHz == null ? 'غير واضح' : r.frequencyHz!.toStringAsFixed(1) + ' Hz'),
        _metric('الانحراف', r.cents == null ? '—' : r.cents!.toStringAsFixed(1) + ' cents'),
        _metric('قوة الإشارة RMS', r.rms.toStringAsFixed(3)),
        _metric('ثقة القراءة', (r.pitchConfidence * 100).toStringAsFixed(0) + '%'),
        const SizedBox(height: 6),
        const Text('قراءة أولية وليست بديلاً عن تحليل استوديو احترافي.', style: TextStyle(fontSize: 11)),
      ],
      if (_path != null && r == null && !_analyzing) const Padding(padding: EdgeInsets.only(top: 8), child: Text('تم حفظ التسجيل محلياً للتحليل.')),
    ])));
  }

  Widget _metric(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
}