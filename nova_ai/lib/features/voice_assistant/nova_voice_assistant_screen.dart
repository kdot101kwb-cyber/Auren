import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Foreground voice-assistant foundation for NOVA.
///
/// This screen captures speech and reads a transparent prototype response.
/// It deliberately does not claim to execute phone or repository actions.
/// Always-on wake-word detection and locked-screen operation are separate work.
class NovaVoiceAssistantScreen extends StatefulWidget {
  const NovaVoiceAssistantScreen({super.key});

  @override
  State<NovaVoiceAssistantScreen> createState() =>
      _NovaVoiceAssistantScreenState();
}

class _NovaVoiceAssistantScreenState extends State<NovaVoiceAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _commandController = TextEditingController();

  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  String _status = 'اضغط على الميكروفون وابدأ الحديث';
  String _reply = 'أنا NOVA. الاستماع الصوتي هنا في مرحلة التأسيس.';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _configureVoice();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _listening = status == 'listening';
            if (!_listening && _status == 'جارٍ الاستماع…') {
              _status = 'انتهى الاستماع';
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _status = 'تعذّر الاستماع: ${error.errorMsg}';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _available = available;
        if (!available) {
          _status = 'خدمة التعرّف على الكلام غير متاحة على هذا الجهاز';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _status = 'تعذّر تهيئة الميكروفون. راجع صلاحيات الجهاز.';
      });
    }
  }

  Future<void> _configureVoice() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  Future<void> _toggleListening() async {
    if (!_available) {
      await _initializeSpeech();
      if (!_available) return;
    }
    if (_listening) {
      await _speech.stop();
      return;
    }
    setState(() {
      _transcript = '';
      _status = 'جارٍ الاستماع…';
    });
    await _speech.listen(
      localeId: 'ar_SA',
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords;
          if (result.finalResult) _status = 'تم تحويل الكلام إلى نص';
        });
      },
    );
  }

  Future<void> _submitText() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    setState(() {
      _transcript = command;
      _reply = 'وصل طلبك إلى واجهة NOVA. تنفيذ الأوامر الذكي غير موصول بعد.';
      _status = 'تم تسجيل الطلب محلياً — لم يُنفّذ أي إجراء خارجي';
      _commandController.clear();
    });
    await _tts.speak(_reply);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA Voice'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6656E8), Color(0xFF16B8C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6656E8).withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  _listening ? Icons.graphic_eq : Icons.mic_none_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'أنا NOVA',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _toggleListening,
              icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(_listening ? 'إيقاف الاستماع' : 'تحدّث مع NOVA'),
            ),
            const SizedBox(height: 24),
            Text('أو اكتب أمرك', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commandController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitText(),
              decoration: InputDecoration(
                hintText: 'مثال: ساعدني في تنظيم مهامي',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'إرسال',
                  onPressed: _submitText,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _TranscriptCard(title: 'ما سمعته NOVA', text: _transcript),
            const SizedBox(height: 12),
            _TranscriptCard(title: 'رد NOVA', text: _reply),
            const SizedBox(height: 16),
            const Text(
              'حدود النسخة الحالية: تحتاج ميزة الصوت إلى دعم الجهاز وصلاحية '
              'الميكروفون. هذه الشاشة لا تنفّذ أوامر الهاتف أو GitHub، ولا '
              'تعمل ككلمة تنبيه دائمة عند إغلاق الشاشة. الرد الصوتي يستخدم '
              'محرك تحويل النص إلى كلام المثبّت على الجهاز.',
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(text.isEmpty ? 'لا يوجد كلام مسجّل بعد' : text),
          ],
        ),
      ),
    );
  }
}
