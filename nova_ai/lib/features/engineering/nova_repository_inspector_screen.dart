import 'package:flutter/material.dart';

import 'nova_repository_inspector.dart';

/// Allows a person to inspect real repository source without granting write access.
class NovaRepositoryInspectorScreen extends StatefulWidget {
  const NovaRepositoryInspectorScreen({super.key});

  @override
  State<NovaRepositoryInspectorScreen> createState() => _NovaRepositoryInspectorScreenState();
}

class _NovaRepositoryInspectorScreenState extends State<NovaRepositoryInspectorScreen> {
  final _pathController = TextEditingController(
    text: 'nova_ai/lib/features/engineering/nova_engineering_orchestrator.dart',
  );
  final _inspector = NovaRepositoryInspector();
  NovaInspectedSource? _source;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pathController.dispose();
    _inspector.close();
    super.dispose();
  }

  Future<void> _inspect() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _source = null;
    });
    try {
      final result = await _inspector.inspect(_pathController.text);
      if (!mounted) return;
      setState(() => _source = result);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() => _error = 'المسار غير مسموح أو غير صالح: ${error.message}');
    } on NovaRepositoryInspectionException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر الاتصال بـ GitHub. تحقق من الإنترنت ثم حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('فحص ملفات AUREN الفعلية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('قراءة فقط من فرع NOVA الحالي. لا تعديل ولا رفع ملفات ولا تشغيل أوامر. المستودع يجب أن يكون متاحاً للقراءة العامة.'),
            const SizedBox(height: 14),
            TextField(
              controller: _pathController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'مسار الملف داخل المستودع',
                hintText: 'nova_ai/lib/...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loading ? null : _inspect(),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loading ? null : _inspect,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(_loading ? 'جارٍ جلب الملف…' : 'جلب الملف وفحصه'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_error!))),
            ],
            if (_source case final source?) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تم جلب مصدر فعلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 8),
                      SelectableText(source.path, textDirection: TextDirection.ltr),
                      const SizedBox(height: 4),
                      Text('الفرع: ${source.ref}', textDirection: TextDirection.ltr),
                      Text('SHA: ${source.sha}'),
                      Text('وقت الجلب: ${source.fetchedAt.toLocal().toIso8601String().substring(0, 19)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      source.content,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('هذه معاينة مصدر فقط، وليست مراجعة آلية أو اقتراح فرق برمجي. لا تُعلن نجاح اختبار أو تعديل دون تشغيله فعلياً.'),
            ],
          ],
        ),
      );
}
