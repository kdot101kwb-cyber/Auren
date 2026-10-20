import 'package:flutter/material.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/everyday/household_inventory_service.dart';
import '../../../services/everyday/household_inventory_store.dart';

/// Device-local household inventory. It does not place orders or contact suppliers.
class AurenHouseholdInventoryScreen extends StatefulWidget {
  const AurenHouseholdInventoryScreen({super.key});

  @override
  State<AurenHouseholdInventoryScreen> createState() =>
      _AurenHouseholdInventoryScreenState();
}

class _AurenHouseholdInventoryScreenState
    extends State<AurenHouseholdInventoryScreen> {
  final _auth = FirebaseAurenAuthService();
  final _store = AurenHouseholdInventoryStore();
  List<AurenHouseholdItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null || uid.trim().isEmpty) {
      if (mounted) setState(() { _loading = false; _error = 'سجّل الدخول أولاً لعرض مخزونك.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _store.loadItems(uid);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = 'تعذّر تحميل المخزون: $error'; _loading = false; });
    }
  }

  Future<void> _editItem([AurenHouseholdItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final category = TextEditingController(text: existing?.category ?? 'منزل');
    final quantity = TextEditingController(text: existing?.quantity.toString() ?? '1');
    final threshold = TextEditingController(text: existing?.lowStockThreshold.toString() ?? '1');
    final unit = TextEditingController(text: existing?.unit ?? 'قطعة');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<AurenHouseholdItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'إضافة عنصر' : 'تعديل العنصر'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, 'اسم العنصر'),
              _field(category, 'الفئة'),
              _field(quantity, 'الكمية الحالية', numeric: true, readOnly: existing != null),
              _field(threshold, 'حد التنبيه للمخزون', numeric: true),
              _field(unit, 'وحدة القياس'),
              _field(notes, 'ملاحظات', requiredField: false),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final item = AurenHouseholdItem(
                id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                name: name.text.trim(),
                category: category.text.trim(),
                quantity: double.parse(quantity.text.trim()),
                lowStockThreshold: double.parse(threshold.text.trim()),
                unit: unit.text.trim(),
                notes: notes.text.trim(),
              );
              final issue = item.validate();
              if (issue != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(issue)));
                return;
              }
              Navigator.pop(dialogContext, item);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    name.dispose(); category.dispose(); quantity.dispose(); threshold.dispose(); unit.dispose(); notes.dispose();
    if (result == null || !mounted) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      await _store.saveItem(uid, result);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذّر الحفظ: $error')));
    }
  }

  Widget _field(TextEditingController controller, String label,
      {bool numeric = false, bool requiredField = true, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'الحقل مطلوب';
          if (numeric && text.isNotEmpty) {
            final number = double.tryParse(text);
            if (number == null || !number.isFinite || number < 0) return 'أدخل رقماً صحيحاً غير سالب';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _moveStock(AurenHouseholdItem item, AurenStockMovementType type) async {
    final amountController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == AurenStockMovementType.restock ? 'إضافة كمية' : 'تسجيل استهلاك'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(amountController, 'الكمية', numeric: true),
          _field(noteController, 'ملاحظة (اختياري)', requiredField: false),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final value = double.parse(amountController.text.trim());
            if (value <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكمية يجب أن تكون أكبر من صفر')));
              return;
            }
            Navigator.pop(dialogContext, value);
          }, child: const Text('تأكيد')),
        ],
      ),
    );
    final note = noteController.text.trim();
    amountController.dispose(); noteController.dispose();
    if (amount == null || !mounted) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      await _store.recordMovement(uid, AurenHouseholdStockMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(), itemId: item.id, type: type, amount: amount,
        note: note, occurredAt: DateTime.now(),
      ));
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذّر تحديث المخزون: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _lowStockOnly
        ? AurenHouseholdRestockPlanner.itemsToRestock(_items)
        : _items;
    final lowCount = AurenHouseholdRestockPlanner.itemsToRestock(_items).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مخزون المنزل'),
        actions: [
          IconButton(tooltip: 'تحديث', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'إضافة عنصر', onPressed: () => _editItem(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.inventory_2_outlined, size: 48),
                    const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12), OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('كل احتياجات البيت في مكان واحد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('تابع الكميات وسجّل الإضافة أو الاستهلاك. لا يتم إرسال طلبات شراء تلقائياً.'),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: _summary('كل العناصر', _items.length, Icons.inventory_2_outlined)),
                            const SizedBox(width: 8),
                            Expanded(child: _summary('تحتاج إعادة تعبئة', lowCount, Icons.warning_amber_rounded)),
                          ]),
                        ],
                      ))),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('عرض العناصر التي وصلت لحد التنبيه فقط'),
                        value: _lowStockOnly,
                        onChanged: (value) => setState(() => _lowStockOnly = value),
                      ),
                      if (visibleItems.isEmpty)
                        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                          const Icon(Icons.check_circle_outline, size: 42),
                          const SizedBox(height: 8),
                          Text(_lowStockOnly ? 'كل شيء متوفر حالياً' : 'لسه ما أضفت أي عنصر'),
                          const SizedBox(height: 8),
                          if (!_lowStockOnly) FilledButton.icon(onPressed: () => _editItem(), icon: const Icon(Icons.add), label: const Text('أضف أول عنصر')),
                        ])))
                      else
                        ...visibleItems.map((item) => Card(
                          child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                            ListTile(
                              leading: CircleAvatar(child: Icon(item.needsRestock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined)),
                              title: Text(item.name),
                              subtitle: Text('${item.category} • ${item.quantity} ${item.unit}\n${item.needsRestock ? 'وصل لحد التنبيه' : 'المخزون جيد'}', maxLines: 2),
                              isThreeLine: true,
                              trailing: IconButton(tooltip: 'تعديل', onPressed: () => _editItem(item), icon: const Icon(Icons.edit_outlined)),
                            ),
                            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Row(children: [
                              Expanded(child: OutlinedButton.icon(onPressed: () => _moveStock(item, AurenStockMovementType.restock), icon: const Icon(Icons.add), label: const Text('إضافة'))),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton.icon(onPressed: item.quantity <= 0 ? null : () => _moveStock(item, AurenStockMovementType.consume), icon: const Icon(Icons.remove), label: const Text('استهلاك'))),
                            ])),
                          ])),
                        )),
                      const SizedBox(height: 12),
                      const Text('البيانات محفوظة على هذا الجهاز فقط؛ حذف بيانات التطبيق قد يؤدي لفقدانها.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
      floatingActionButton: !_loading && _error == null
          ? FloatingActionButton.extended(onPressed: () => _editItem(), icon: const Icon(Icons.add), label: const Text('عنصر جديد'))
          : null,
    );
  }

  Widget _summary(String label, int count, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon), const SizedBox(height: 8),
      Text('$count', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
