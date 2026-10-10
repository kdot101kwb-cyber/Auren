import 'package:flutter/material.dart';

/// Local prototype for organizing a trade opportunity.
/// It does not persist data or contact buyers, suppliers, banks, or carriers.
class AurenTradeDealScreen extends StatefulWidget {
  const AurenTradeDealScreen({super.key});

  @override
  State<AurenTradeDealScreen> createState() => _AurenTradeDealScreenState();
}

class _AurenTradeDealScreenState extends State<AurenTradeDealScreen> {
  final _product = TextEditingController();
  final _counterparty = TextEditingController();
  final _quantity = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();

  static const _stages = <String>[
    'تحديد الاحتياج',
    'طلب عروض الأسعار',
    'مقارنة العروض',
    'التحقق من الطرف',
    'التفاوض والاتفاق',
    'الشحن والمستندات',
    'اكتملت الصفقة',
  ];

  int _stage = 0;
  String _currency = 'USD';

  @override
  void dispose() {
    _product.dispose();
    _counterparty.dispose();
    _quantity.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة صفقة تجارية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'نظّم رحلة الصفقة من تحديد المنتج إلى إغلاقها. هذه نسخة أولية تحفظ الحالة داخل الشاشة فقط؛ لا تُرسل رسائل ولا تحفظ البيانات بعد إغلاقها.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _product,
            decoration: const InputDecoration(
              labelText: 'المنتج أو الخدمة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _counterparty,
            decoration: const InputDecoration(
              labelText: 'اسم المورد أو المشتري (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            decoration: const InputDecoration(
              labelText: 'الكمية',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'قيمة الصفقة التقديرية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _currency,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                  DropdownMenuItem(value: 'KES', child: Text('KES')),
                  DropdownMenuItem(value: 'AED', child: Text('AED')),
                  DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _currency = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظات وشروط ومواعيد',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('مرحلة الصفقة', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_stage + 1) / _stages.length),
          const SizedBox(height: 8),
          ...List.generate(_stages.length, (index) {
            return RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: index,
              groupValue: _stage,
              title: Text(_stages[index]),
              secondary: Icon(
                index < _stage
                    ? Icons.check_circle
                    : index == _stage
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
              ),
              onChanged: (value) {
                if (value != null) setState(() => _stage = value);
              },
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final details = [
                'متابعة صفقة تجارية',
                'المنتج/الخدمة: ${_product.text.trim().isEmpty ? 'غير محدد' : _product.text.trim()}',
                'الطرف: ${_counterparty.text.trim().isEmpty ? 'لم يحدد بعد' : _counterparty.text.trim()}',
                'الكمية: ${_quantity.text.trim().isEmpty ? 'غير محددة' : _quantity.text.trim()}',
                'القيمة التقديرية: ${_value.text.trim().isEmpty ? 'غير محددة' : '${_value.text.trim()} $_currency'}',
                'المرحلة: ${_stages[_stage]}',
                if (_notes.text.trim().isNotEmpty) 'ملاحظات: ${_notes.text.trim()}',
              ].join('\n');
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ملخص الصفقة'),
                  content: SingleChildScrollView(child: SelectableText(details)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.summarize_outlined),
            label: const Text('عرض ملخص الصفقة'),
          ),
          const SizedBox(height: 12),
          const Text(
            'قبل الدفع أو الشحن، تحقق بشكل مستقل من هوية الطرف، والعقد، وشروط الدفع، والتراخيص والمستندات المطلوبة.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
