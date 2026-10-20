import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

/// Guided translation and terminology workflow using the existing AUREN assistant.
class AurenLanguageBridgeScreen extends StatefulWidget {
  const AurenLanguageBridgeScreen({super.key});

  @override
  State<AurenLanguageBridgeScreen> createState() => _AurenLanguageBridgeScreenState();
}

class _AurenLanguageBridgeScreenState extends State<AurenLanguageBridgeScreen> {
  final _contentController = TextEditingController();
  final _sourceLanguageController = TextEditingController();
  final _targetLanguageController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _sourceLanguageController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  void _translate() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل النص أو المصطلح أولاً.')),
      );
      return;
    }

    final source = _sourceLanguageController.text.trim();
    final target = _targetLanguageController.text.trim();
    final prompt = 'ساعدني في ترجمة وفهم النص التالي. '
        'حافظ على المعنى والسياق، واشرح المصطلحات التي تحتمل أكثر من معنى، '
        'ولا تضف معلومات غير موجودة في النص. '
        '${source.isEmpty ? '' : 'لغة المصدر: $source. '}'
        '${target.isEmpty ? '' : 'اللغة المطلوبة: $target. '}'
        'اعرض الترجمة أولاً ثم ملاحظات مختصرة عند الحاجة.\n\nالنص:\n$content';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Language Bridge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'المعنى أولاً، ثم الترجمة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ترجمة موجهة مع توضيح المصطلحات والسياق. راجع الترجمة المتخصصة '
            'قبل استخدامها في المستندات القانونية أو الطبية أو الرسمية.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _sourceLanguageController,
            decoration: const InputDecoration(
              labelText: 'لغة النص (اختياري)',
              hintText: 'مثال: English',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetLanguageController,
            decoration: const InputDecoration(
              labelText: 'اللغة المطلوبة (اختياري)',
              hintText: 'مثال: العربية',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'النص أو المصطلح',
              hintText: 'الصق النص هنا…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _translate,
            icon: const Icon(Icons.translate),
            label: const Text('افهم وترجم'),
          ),
        ],
      ),
    );
  }
}
