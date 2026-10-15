import 'package:flutter/material.dart';

/// A planning calculator only: values are supplied by the user and are not
/// live market quotes, certified engineering estimates, or financial advice.
class AurenRawToProductScreen extends StatefulWidget {
  const AurenRawToProductScreen({super.key});

  @override
  State<AurenRawToProductScreen> createState() =>
      _AurenRawToProductScreenState();
}

class _AurenRawToProductScreenState extends State<AurenRawToProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rawQuantity = TextEditingController(text: '1000');
  final _yieldPercent = TextEditingController(text: '85');
  final _rawUnitCost = TextEditingController(text: '1');
  final _processingPerRawUnit = TextEditingController(text: '0.4');
  final _packagingPerProduct = TextEditingController(text: '0.2');
  final _transport = TextEditingController(text: '100');
  final _otherCosts = TextEditingController(text: '50');
  final _sellingPrice = TextEditingController(text: '3');
  final _rawName = TextEditingController(text: 'المادة الخام');
  final _productName = TextEditingController(text: 'المنتج النهائي');
  String _currency = 'USD';

  @override
  void dispose() {
    for (final controller in [
      _rawQuantity,
      _yieldPercent,
      _rawUnitCost,
      _processingPerRawUnit,
      _packagingPerProduct,
      _transport,
      _otherCosts,
      _sellingPrice,
      _rawName,
      _productName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  String _money(double value) =>
      '${value.toStringAsFixed(2)} $_currency';

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? helper,
    double? min,
    double? max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final parsed = double.tryParse(
            (value ?? '').trim().replaceAll(',', '.'),
          );
          if (parsed == null || !parsed.isFinite) {
            return 'أدخل رقماً صحيحاً';
          }
          if (min != null && parsed < min) return 'القيمة يجب ألا تقل عن $min';
          if (max != null && parsed > max) return 'القيمة يجب ألا تزيد عن $max';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _result(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
                fontSize: emphasized ? 17 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawQty = _number(_rawQuantity);
    final yieldRate = _number(_yieldPercent) / 100;
    final outputQty = rawQty * yieldRate;
    final rawCosts = rawQty * (_number(_rawUnitCost) +
        _number(_processingPerRawUnit));
    final packagingCosts = outputQty * _number(_packagingPerProduct);
    final totalCosts = rawCosts +
        packagingCosts +
        _number(_transport) +
        _number(_otherCosts);
    final revenue = outputQty * _number(_sellingPrice);
    final profit = revenue - totalCosts;
    final margin = revenue > 0 ? profit / revenue * 100 : 0.0;
    final costPerProduct = outputQty > 0 ? totalCosts / outputQty : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('من الخام إلى المنتج'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خطّط لسلسلة التصنيع',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل بياناتك لمقارنة تكلفة تحويل الخام إلى منتج نهائي. '
                      'النتائج تقديرية وتعتمد بالكامل على الأرقام التي تدخلها.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'عملة الحساب',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD — دولار')),
                        DropdownMenuItem(value: 'SDG', child: Text('SDG — جنيه سوداني')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR — يورو')),
                        DropdownMenuItem(value: 'SAR', child: Text('SAR — ريال سعودي')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('١. المادة الخام والمنتج', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _textField(_rawName, 'اسم المادة الخام'),
            _textField(_productName, 'اسم المنتج النهائي'),
            _numberField(_rawQuantity, 'كمية الخام', helper: 'بوحدة قياس واحدة مثل كجم', min: 0.000001),
            _numberField(_yieldPercent, 'نسبة التحويل إلى منتج صالح (%)', min: 0, max: 100),
            const SizedBox(height: 8),
            Text('٢. تكاليف الإنتاج', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _numberField(_rawUnitCost, 'تكلفة وحدة الخام', min: 0),
            _numberField(_processingPerRawUnit, 'المعالجة لكل وحدة خام', min: 0),
            _numberField(_packagingPerProduct, 'التغليف لكل وحدة منتج', min: 0),
            _numberField(_transport, 'النقل والشحن إجمالاً', min: 0),
            _numberField(_otherCosts, 'تكاليف أخرى إجمالاً', min: 0),
            const SizedBox(height: 8),
            Text('٣. البيع والنتيجة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _numberField(_sellingPrice, 'سعر بيع وحدة المنتج', min: 0),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('احسب خطة التصنيع'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('النتيجة التقديرية', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _result('المادة الخام', _rawName.text),
                    _result('المنتج النهائي', _productName.text),
                    _result('الكمية المتوقعة بعد التحويل', outputQty.toStringAsFixed(2)),
                    const Divider(),
                    _result('تكلفة الخام والمعالجة', _money(rawCosts)),
                    _result('تكلفة التغليف', _money(packagingCosts)),
                    _result('النقل والتكاليف الأخرى', _money(_number(_transport) + _number(_otherCosts))),
                    _result('إجمالي تكلفة الإنتاج', _money(totalCosts), emphasized: true),
                    _result('تكلفة الوحدة النهائية', _money(costPerProduct)),
                    _result('إيرادات البيع المتوقعة', _money(revenue)),
                    _result('الربح أو الخسارة التقديرية', _money(profit), emphasized: true),
                    _result('هامش الربح من المبيعات', '${margin.toStringAsFixed(1)}%'),
                    const SizedBox(height: 8),
                    const Text(
                      'تنبيه: لا تشمل هذه الحسبة الضرائب أو التمويل أو تغير الأسعار '
                      'إلا إذا أُدخلت ضمن التكاليف الأخرى. تحقق من جودة الخام '
                      'والهدر والمواصفات والأسعار الفعلية قبل اتخاذ قرار استثماري.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
