import 'package:flutter/material.dart';

import '../../../services/social/community_appeals_service.dart';

/// Participant-facing appeal form. Eligibility is checked by the service and
/// independently enforced by Firestore rules.
class AurenCommunityAppealScreen extends StatefulWidget {
  const AurenCommunityAppealScreen({super.key});

  @override
  State<AurenCommunityAppealScreen> createState() =>
      _AurenCommunityAppealScreenState();
}

class _AurenCommunityAppealScreenState
    extends State<AurenCommunityAppealScreen> {
  final _service = AurenCommunityAppealsService();
  final _reportId = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reportId.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final id = await _service.submit(
        reportId: _reportId.text,
        reason: _reason.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال الاستئناف المحلي: $id')),
      );
      _reportId.clear();
      _reason.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الاستئناف: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('استئناف قرار مجتمع')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'يمكن لمشارك البلاغ تقديم استئناف بعد صدور قرار نهائي. '
              'لن يُقبل الاستئناف إذا لم تكن طرفاً في البلاغ أو لم يُحسم بعد.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reportId,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'معرّف البلاغ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLength: 1000,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'سبب الاستئناف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.gavel_outlined),
              label: Text(_saving ? 'جارٍ الإرسال…' : 'إرسال الاستئناف'),
            ),
          ],
        ),
      );
}
