import 'package:flutter/material.dart';

import '../domain/personal_finance_models.dart';

/// First interactive Personal Finance prototype. Entries remain in memory only.
class AurenPersonalFinanceScreen extends StatefulWidget {
  const AurenPersonalFinanceScreen({super.key});

  @override
  State<AurenPersonalFinanceScreen> createState() =>
      _AurenPersonalFinanceScreenState();
}

class _AurenPersonalFinanceScreenState extends State<AurenPersonalFinanceScreen> {
  final List<FinanceEntry> _entries = [];
  String _currency = 'SDG';
  double _budgetLimit = 100000;
  int _nextId = 1;

  PersonalFinanceSummary get _summary => PersonalFinanceSummary.calculate(
        entries: _entries,
        budget: FinanceBudget(month: DateTime.now(), limit: _budgetLimit, currency: _currency),
      );

  String _money(double value) => value.toStringAsFixed(2) + ' ' + _currency;

  Future<void> _addEntry() async {
    final result = await showDialog<_EntryDraft>(
      context: context,
      builder: (context) => const _AddFinanceEntryDialog(),
    );
    if (!mounted || result == null) return;
    setState(() {
      _entries.insert(0, FinanceEntry(
        id: 'local-' + (_nextId++).toString(),
        type: result.type,
        amount: result.amount,
        currency: _currency,
        category: result.category,
        occurredAt: DateTime.now(),
        note: result.note,
      ));
    });
  }

  Future<void> _editBudget() async {
    final controller = TextEditingController(text: _budgetLimit.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل ميزانية الشهر'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'الحد الشهري (' + _currency + ')', border: const OutlineInputBorder()),
            validator: (text) {
              final parsed = double.tryParse((text ?? '').trim());
              if (parsed == null || !parsed.isFinite || parsed <= 0) return 'أدخل مبلغاً أكبر من صفر';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, double.parse(controller.text.trim()));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null) return;
    setState(() => _budgetLimit = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('أموالي وميزانيتي'),
        actions: [IconButton(tooltip: 'تعديل الميزانية', onPressed: _editBudget, icon: const Icon(Icons.tune))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل حركة'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primaryContainer, theme.colorScheme.tertiaryContainer],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الصافي المسجّل', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_money(summary.net), key: const Key('finance-net'), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _Metric(label: 'الدخل', value: _money(summary.income), icon: Icons.south_west)),
                    const SizedBox(width: 12),
                    Expanded(child: _Metric(label: 'المصروفات', value: _money(summary.expenses), icon: Icons.north_east)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.pie_chart_outline),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('ميزانية الشهر', style: TextStyle(fontWeight: FontWeight.w700))),
                  TextButton(onPressed: _editBudget, child: const Text('تعديل')),
                ]),
                Text(_money(summary.expensesInBudgetMonth) + ' من ' + _money(summary.budgetLimit)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: (summary.expensesInBudgetMonth / summary.budgetLimit).clamp(0.0, 1.0),
                    color: summary.isOverBudget ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.isOverBudget
                      ? 'تجاوزت الميزانية بمقدار ' + _money(-summary.budgetRemaining)
                      : 'المتبقي ' + _money(summary.budgetRemaining),
                  key: const Key('finance-budget-status'),
                  style: TextStyle(
                    color: summary.isOverBudget ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Text('آخر الحركات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            Text(_entries.length.toString()),
          ]),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 36),
                  SizedBox(height: 10),
                  Text('لسه ما سجلت أي حركة', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('أضف دخلك أو مصروفاتك عشان تشوف ملخصك المالي.', textAlign: TextAlign.center),
                ]),
              ),
            )
          else
            ..._entries.map((entry) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(entry.type == FinanceEntryType.income ? Icons.south_west : Icons.north_east)),
                title: Text(entry.category),
                subtitle: Text(entry.type == FinanceEntryType.income ? 'دخل' : 'مصروف'),
                trailing: Text(
                  (entry.type == FinanceEntryType.income ? '+' : '−') + _money(entry.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: entry.type == FinanceEntryType.income ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ),
            )),
          const SizedBox(height: 12),
          const Text('ملاحظة: هذه نسخة أولية؛ الحركات محفوظة داخل الشاشة فقط ولن تبقى بعد إغلاقها.', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ])),
    ],
  );
}

class _EntryDraft {
  const _EntryDraft({required this.type, required this.amount, required this.category, this.note});
  final FinanceEntryType type;
  final double amount;
  final String category;
  final String? note;
}

class _AddFinanceEntryDialog extends StatefulWidget {
  const _AddFinanceEntryDialog();
  @override
  State<_AddFinanceEntryDialog> createState() => _AddFinanceEntryDialogState();
}

class _AddFinanceEntryDialogState extends State<_AddFinanceEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  FinanceEntryType _type = FinanceEntryType.expense;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تسجيل حركة مالية'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SegmentedButton<FinanceEntryType>(
            segments: const [
              ButtonSegment(value: FinanceEntryType.expense, label: Text('مصروف'), icon: Icon(Icons.north_east)),
              ButtonSegment(value: FinanceEntryType.income, label: Text('دخل'), icon: Icon(Icons.south_west)),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('finance-entry-amount'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
            validator: (text) {
              final amount = double.tryParse((text ?? '').trim());
              if (amount == null || !amount.isFinite || amount <= 0) return 'أدخل مبلغاً صحيحاً أكبر من صفر';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'التصنيف (مثلاً: طعام)', border: OutlineInputBorder()),
            validator: (text) => (text ?? '').trim().isEmpty ? 'التصنيف مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _note, maxLength: 500, decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', border: OutlineInputBorder())),
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, _EntryDraft(
            type: _type,
            amount: double.parse(_amount.text.trim()),
            category: _category.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ));
        },
        child: const Text('حفظ الحركة'),
      ),
    ],
  );
}
