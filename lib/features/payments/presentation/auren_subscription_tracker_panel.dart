import 'package:flutter/material.dart';

import '../../../services/payments/auren_subscription_tracker.dart';

/// Explicitly user-maintained recurring bills; no bank connection or payments.
class AurenSubscriptionTrackerPanel extends StatefulWidget {
  const AurenSubscriptionTrackerPanel({required this.uid, super.key});

  final String uid;

  @override
  State<AurenSubscriptionTrackerPanel> createState() =>
      _AurenSubscriptionTrackerPanelState();
}

class _AurenSubscriptionTrackerPanelState
    extends State<AurenSubscriptionTrackerPanel> {
  final _tracker = const AurenSubscriptionTracker();
  List<AurenSubscription> _records = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await _tracker.load(widget.uid);
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الاشتراكات المحفوظة محلياً.';
      });
    }
  }

  Future<void> _persist(List<AurenSubscription> records) async {
    try {
      await _tracker.save(widget.uid, records);
      if (!mounted) return;
      setState(() {
        _records = records..sort((a, b) => a.nextDue.compareTo(b.nextDue));
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم حفظ التغيير: $error')),
      );
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final currency = TextEditingController(text: 'USD');
    final notes = TextEditingController();
    var due = DateTime.now().add(const Duration(days: 30));
    var cadence = 30;
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('إضافة اشتراك أو فاتورة متكررة'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'أدخل الاسم' : null,
                  ),
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ بالأصغر وحدة (مثلاً 1299 = 12.99)',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      return parsed == null || parsed <= 0
                          ? 'أدخل مبلغاً صحيحاً موجباً'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: currency,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: 'العملة (USD / SDG)'),
                    validator: (value) =>
                        !RegExp(r'^[A-Za-z]{3}$').hasMatch(value?.trim() ?? '')
                            ? 'استخدم رمز عملة من 3 أحرف'
                            : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: cadence,
                    decoration: const InputDecoration(labelText: 'التكرار'),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('أسبوعي')),
                      DropdownMenuItem(value: 30, child: Text('شهري (تقريبي)')),
                      DropdownMenuItem(value: 90, child: Text('كل 3 أشهر')),
                      DropdownMenuItem(value: 365, child: Text('سنوي')),
                    ],
                    onChanged: (value) => refreshDialog(() => cadence = value ?? 30),
                  ),
                  TextFormField(
                    controller: notes,
                    maxLength: 500,
                    decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                  ),
                  const SizedBox(height: 8),
                  Text('موعد الاستحقاق: ${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}'),
                  TextButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: due,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) refreshDialog(() => due = selected);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('اختيار الموعد'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      final record = AurenSubscription(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        amountMinor: int.parse(amount.text.trim()),
        currency: currency.text.trim().toUpperCase(),
        nextDue: due,
        cadenceDays: cadence,
        notes: notes.text.trim(),
      );
      await _persist([..._records, record]);
    }
    name.dispose();
    amount.dispose();
    currency.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _tracker.summarize(_records, now: DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('الاشتراكات والفواتير',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'إضافة اشتراك',
                  onPressed: _loading ? null : _add,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Text(
              'سجّل الاشتراكات يدوياً وتابع مواعيدها. لا يوجد اتصال بالبنوك أو إلغاء تلقائي أو دفع.',
              style: TextStyle(fontSize: 12),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
            if (!_loading && _records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد اشتراكات مسجلة. أضف اشتراكاً لتتبع موعده وتكلفته.'),
              ),
            if (_records.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('النشطة: ${summary.activeCount}'),
              ...summary.totalsByCurrency.entries.map((entry) => Text(
                    'المجموع المتكرر المسجّل • ${entry.key}: ${entry.value} وحدة صغرى',
                  )),
              const Divider(),
              ..._records.map((record) {
                final due = record.nextDue;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(record.active ? Icons.repeat : Icons.pause_circle_outline),
                  title: Text(record.name),
                  subtitle: Text(
                    '${record.amountMinor} ${record.currency} • الاستحقاق ${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')} • كل ${record.cadenceDays} يوم',
                  ),
                  isThreeLine: record.notes.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'toggle') {
                        _persist(_records
                            .map((item) => item.id == record.id
                                ? AurenSubscription(
                                    id: item.id,
                                    name: item.name,
                                    amountMinor: item.amountMinor,
                                    currency: item.currency,
                                    nextDue: item.nextDue,
                                    cadenceDays: item.cadenceDays,
                                    active: !item.active,
                                    notes: item.notes,
                                  )
                                : item)
                            .toList());
                      } else if (action == 'delete') {
                        _persist(_records.where((item) => item.id != record.id).toList());
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(record.active ? 'إيقاف التتبع' : 'استئناف التتبع'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('حذف السجل')),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
