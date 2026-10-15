import 'package:flutter/material.dart';
import '../domain/manufacturing_route_catalog.dart';
import '../domain/raw_to_product_estimate.dart';

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
  String _routeId = 'cotton-to-garment';

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

  double _number(TextEditingController controller) {
    final parsed = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

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
    final selectedRoute = ManufacturingRouteCatalog.findById(_routeId)!;
    final estimate = RawToProductEstimate.calculate(
      rawQuantity: _number(_rawQuantity),
      yieldPercent: _number(_yieldPercent),
      rawUnitCost: _number(_rawUnitCost),
      processingPerRawUnit: _number(_processingPerRawUnit),
      packagingPerProduct: _number(_packagingPerProduct),
      transportCost: _number(_transport),
      otherCosts: _number(_otherCosts),
      sellingPricePerProduct: _number(_sellingPrice),
    );
    final outputQty = estimate.outputQuantity;
    final rawCosts = estimate.rawAndProcessingCost;
    final packagingCosts = estimate.packagingCost;
    final totalCosts = estimate.totalCost;
    final revenue = estimate.revenue;
    final profit = estimate.profitOrLoss;
    final margin = estimate.salesMarginPercent;
    final costPerProduct = estimate.unitCost;

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مسار التصنيع المقترح', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'اختر مثالاً لتسلسل المراحل. هذه مسارات إرشادية وليست تعليمات تشغيل أو اعتماداً هندسياً.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _routeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'نوع سلسلة التصنيع',
                        border: OutlineInputBorder(),
                      ),
                      items: ManufacturingRouteCatalog.routes.map((route) =>
                        DropdownMenuItem<String>(
                          value: route.id,
                          child: Text('${route.rawMaterial} ← ${route.finalProduct}', overflow: TextOverflow.ellipsis),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final route = ManufacturingRouteCatalog.findById(value);
                        if (route == null) return;
                        setState(() {
                          _routeId = value;
                          _rawName.text = route.rawMaterial;
                          _productName.text = route.finalProduct;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(selectedRoute.overview),
                    const SizedBox(height: 12),
                    ...selectedRoute.stages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stage = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(stage.purpose),
                                  const SizedBox(height: 3),
                                  Text(
                                    "الناتج المعتاد: ${stage.typicalOutputs.join('، ')}",
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Text('قبل البدء', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    ...selectedRoute.prerequisites.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.checklist_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    )),
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
