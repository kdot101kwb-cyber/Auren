import 'package:flutter/material.dart';
import '../../../services/talent/music_audio_recorder.dart';

class AurenMusicAudioLab extends StatefulWidget {
  const AurenMusicAudioLab({super.key});

  @override
  State<AurenMusicAudioLab> createState() => _AurenMusicAudioLabState();
}

class _AurenMusicAudioLabState extends State<AurenMusicAudioLab> {
  final _recorder = AurenMusicAudioRecorder();
  static const _targetNotes = <String>[
    'C3', 'D3', 'E3', 'F3', 'G3', 'A3', 'B3',
    'C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4',
  ];

  bool _recording = false;
  bool _analyzing = false;
  String _targetNote = 'A3';
  String? _path;
  String? _error;
  AurenMusicAudioAnalysis? _result;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    setState(() => _error = null);
    if (_recording) {
      try {
        final path = await _recorder.stopRecording();
        if (!mounted) return;
        setState(() {
          _recording = false;
          _path = path;
        });
        if (path != null) await _analyze(path);
      } catch (e) {
        if (mounted) {
          setState(() {
            _recording = false;
            _error = 'تعذر إيقاف التسجيل: $e';
          });
        }
      }
      return;
    }

    try {
      if (!await _recorder.requestPermission()) {
        if (mounted) setState(() => _error = 'لم يتم السماح باستخدام الميكروفون.');
        return;
      }
      final path = await _recorder.startWavRecording();
      if (!mounted) return;
      if (path == null) {
        setState(() => _error = 'تعذر بدء التسجيل.');
        return;
      }
      setState(() {
        _recording = true;
        _path = null;
        _result = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر بدء التسجيل: $e');
    }
  }

  Future<void> _analyze(String path) async {
    setState(() => _analyzing = true);
    try {
      final result = await _recorder.analyzeWav(path);
      if (!mounted) return;
      setState(() => _result = result);
      if (result == null) setState(() => _error = 'تعذر تحليل ملف الصوت.');
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ أثناء التحليل: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  int? _midiNumber(String note) {
    final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
    if (match == null) return null;
    const semitones = <String, int>{
      'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
      'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11,
    };
    final octave = int.tryParse(match.group(2)!);
    final semitone = semitones[match.group(1)!];
    if (octave == null || semitone == null) return null;
    return (octave + 1) * 12 + semitone;
  }

  double? _offsetFromTarget(AurenMusicAudioAnalysis result) {
    final note = result.note;
    final midi = note == null ? null : _midiNumber(note);
    final target = _midiNumber(_targetNote);
    if (midi == null || target == null || result.cents == null) return null;
    return (midi - target) * 100 + result.cents!;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final offset = result == null ? null : _offsetFromTarget(result);
    final inTune = offset != null && offset.abs() <= 25;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎙️ Music Audio Lab',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'سجّل صوتك لتحصل على قراءة أولية للنوتة والتردد، أو استخدم تمرين مطابقة النغمة.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _targetNote,
              decoration: const InputDecoration(
                labelText: 'النوتة المستهدفة للتمرين',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              items: _targetNotes
                  .map((note) => DropdownMenuItem(value: note, child: Text(note)))
                  .toList(),
              onChanged: _recording || _analyzing
                  ? null
                  : (value) => setState(() => _targetNote = value ?? _targetNote),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _analyzing ? null : _toggle,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(_recording ? 'إيقاف التسجيل وتحليله' : 'سجّل النغمة'),
              ),
            ),
            if (_recording)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: colorScheme.error)),
              ),
            if (result != null) ...[
              const Divider(height: 24),
              const Text('نتيجة التحليل', style: TextStyle(fontWeight: FontWeight.w900)),
              _metric('النوتة المقروءة', result.note ?? 'غير واضحة'),
              _metric(
                'التردد',
                result.frequencyHz == null
                    ? 'غير واضح'
                    : '${result.frequencyHz!.toStringAsFixed(1)} Hz',
              ),
              _metric(
                'الانحراف عن أقرب نوتة',
                result.cents == null ? '—' : '${result.cents!.toStringAsFixed(1)} cents',
              ),
              _metric('قوة الإشارة RMS', result.rms.toStringAsFixed(3)),
              _metric(
                'مؤشر القراءة التقريبي',
                '${(result.pitchConfidence * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تمرين مطابقة النغمة: $_targetNote',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      offset == null
                          ? 'لم نتمكن من تحديد النغمة بوضوح. جرّب التسجيل في مكان أهدأ.'
                          : inTune
                              ? 'قريب جدًا من النغمة المستهدفة! حافظ على ثبات الصوت.'
                              : offset < 0
                                  ? 'النغمة أخفض من الهدف بحوالي ${offset.abs().toStringAsFixed(0)} سنت.'
                                  : 'النغمة أعلى من الهدف بحوالي ${offset.toStringAsFixed(0)} سنت.',
                    ),
                    if (offset != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (1 - (offset.abs() / 300)).clamp(0.0, 1.0),
                          color: inTune ? Colors.green : colorScheme.primary,
                          backgroundColor: colorScheme.outlineVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'فرق عن الهدف: ${offset > 0 ? '+' : ''}${offset.toStringAsFixed(1)} cents',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'التحليل محلي وأولي، وقد يتأثر بالضوضاء أو تعدد النغمات. ليس تقييماً احترافياً للصوت.',
                style: TextStyle(fontSize: 11),
              ),
            ],
            if (_path != null && result == null && !_analyzing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('تم حفظ التسجيل محلياً للتحليل.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}
