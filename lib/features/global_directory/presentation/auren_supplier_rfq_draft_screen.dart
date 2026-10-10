import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prepares an editable RFQ draft. It never sends a message to a supplier.
class AurenSupplierRfqDraftScreen extends StatefulWidget {
  const AurenSupplierRfqDraftScreen({super.key});

  @override
  State<AurenSupplierRfqDraftScreen> createState() =>
      _AurenSupplierRfqDraftScreenState();
}

class _AurenSupplierRfqDraftScreenState
    extends State<AurenSupplierRfqDraftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _contactController = TextEditingController();
  String _currency = 'USD';
  String _delivery = 'شحن إلى العنوان';
  String? _draft;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _destinationController.dispose();
    _specificationsController.dispose();
    _budgetController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _buildDraft() {
    final budget = _budgetController.text.trim();
    final specs = _specificationsController.text.trim();
    final contact = _contactController.text.trim();
    return '''
طلب عرض سعر (RFQ)

مرحباً،
نرغب في الحصول على عرض سعر للمنتج/الخدمة التالية:
- المنتج أو الخدمة: ${_productController.text.trim()}
- الكمية المطلوبة: ${_quantityController.text.trim()}
- المواصفات: ${specs.isEmpty ? 'يرجى اقتراح الخيارات المتاحة' : specs}
- الوجهة: ${_destinationController.text.trim()}
- طريقة التسليم: $_delivery
- الميزانية المستهدفة: ${budget.isEmpty ? 'يرجى توضيح الأسعار المتاحة' : '$budget $_currency'}
${contact.isEmpty ? '' : '- وسيلة التواصل التي سنستخدمها: $contact'}

يرجى إرسال السعر التفصيلي، والحد الأدنى للطلب، ومدة التجهيز والتسليم، وشروط الدفع والضمان، ومدة صلاحية العرض. يرجى توضيح أي رسوم إضافية.

شكراً لكم.
'''.trim();
  }

  Future<void> _copyDraft() async {
    final draft = _draft;
    if (draft == null) return;
    await Clipboard.setData(ClipboardData(text: draft));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ مسودة طلب عرض السعر. لم يتم إرسالها لأي جهة.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب عرض سعر من مورد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: const Text(
              'أدخل تفاصيل طلبك لتجهيز مسودة واضحة يمكنك مراجعتها وتعديلها ثم نسخها. لن يتم التواصل مع أي مورد تلقائياً.',
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _productController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'المنتج أو الخدمة *',
                    hintText: 'مثال: أقمشة قطنية أو معدات تعبئة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب اسم المنتج أو الخدمة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الكمية المطلوبة *',
                    hintText: 'مثال: 500 قطعة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الكمية المطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'مدينة وبلد التسليم *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'حدد وجهة التسليم'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specificationsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'المواصفات المطلوبة (اختياري)',
                    hintText: 'المقاس، المادة، الجودة، الموديل، الشهادات...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _delivery,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التسليم',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'شحن إلى العنوان',
                      child: Text('شحن إلى العنوان'),
                    ),
                    DropdownMenuItem(
                      value: 'استلام من المورد',
                      child: Text('استلام من المورد'),
                    ),
                    DropdownMenuItem(
                      value: 'يُحدّد لاحقاً',
                      child: Text('يُحدّد لاحقاً'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _delivery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'الميزانية (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          labelText: 'العملة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                          DropdownMenuItem(value: 'KES', child: Text('KES')),
                          DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _currency = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'وسيلة التواصل التي ستستخدمها (اختياري)',
                    hintText: 'بريد عمل أو رقم هاتف مخصص',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _draft = _buildDraft());
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('إنشاء مسودة طلب السعر'),
                ),
              ],
            ),
          ),
          if (_draft != null) ...[
            const SizedBox(height: 24),
            Text('راجع المسودة', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(_draft!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyDraft,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ المسودة'),
            ),
            const SizedBox(height: 8),
            const Text(
              'قبل الإرسال، تحقق من هوية المورد وسجله وشروط الدفع والشحن. لا ترسل مستندات حساسة أو دفعات قبل التحقق.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
