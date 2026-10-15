import 'package:flutter/material.dart';
import '../domain/manufacturing_route_catalog.dart';
import '../domain/raw_to_product_estimate.dart';
import 'raw_to_product_strings.dart';
import 'raw_to_product_stage_strings.dart';

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
  final _rawName = TextEditingController();
  final _productName = TextEditingController();
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

  String _normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var normalized = value.trim();
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabic[i], '$i');
      normalized = normalized.replaceAll(persian[i], '$i');
    }
    return normalized;
  }

  double? _parseAmount(String value) {
    var normalized = _normalizeDigits(value)
        .replaceAll('\u066B', '.')
        .replaceAll('\u066C', ',')
        .replaceAll(RegExp(r'[\\s\\u00A0\\u202F]'), '');
    if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(normalized)) {
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '.');
    }
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed.isFinite ? parsed : null;
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
          final parsed = _parseAmount(value ?? '');
          if (parsed == null || !parsed.isFinite) {
            return RawToProductStrings(Localizations.localeOf(context).languageCode).invalid;
          }
          if (min != null && parsed < min) return RawToProductStrings(Localizations.localeOf(context).languageCode).min(min);
          if (max != null && parsed > max) return RawToProductStrings(Localizations.localeOf(context).languageCode).max(max);
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
            value == null || value.trim().isEmpty
                ? RawToProductStrings(Localizations.localeOf(context).languageCode).required
                : null,
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
    final l = RawToProductStrings(Localizations.localeOf(context).languageCode);
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
        title: Text(l.title),
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
                      l.plan,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(l.intro),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: InputDecoration(
                        labelText: l.currency,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'SAR', child: Text('SAR')),
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
                    Text(l.route, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l.routeHelp),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _routeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.routeType,
                        border: OutlineInputBorder(),
                      ),
                      items: ManufacturingRouteCatalog.routes.map((route) =>
                        DropdownMenuItem<String>(
                          value: route.id,
                          child: Text(l.routeName(route.id), overflow: TextOverflow.ellipsis),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final route = ManufacturingRouteCatalog.findById(value);
                        if (route == null) return;
                        setState(() {
                          _routeId = value;
                          final names = l.routeName(value).split(RegExp('[←→]'));
                          _rawName.text = names.first.trim();
                          _productName.text = names.length > 1 ? names.last.trim() : l.routeName(value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(l.stageHelp),
                    const SizedBox(height: 12),
                    ...selectedRoute.stages.asMap().entries.map((entry) {
                      final index = entry.key;
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
                                  Text(
                                    RawToProductStageStrings.name(
                                      selectedRoute.id,
                                      index,
                                      Localizations.localeOf(context).languageCode,
                                      l.stageName(index),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    RawToProductStageStrings.purpose(
                                      selectedRoute.id,
                                      index,
                                      Localizations.localeOf(context).languageCode,
                                      l.stageHelp,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Text(l.before, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    ...l.prerequisites.map((item) => Padding(
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
            Text('1. ${l.raw} & ${l.product}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _textField(_rawName, l.rawName),
            _textField(_productName, l.productName),
            _numberField(_rawQuantity, l.rawQty, helper: l.qtyHelp, min: 0.000001),
            _numberField(_yieldPercent, l.yield, min: 0, max: 100),
            const SizedBox(height: 8),
            Text(l.costs, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _numberField(_rawUnitCost, l.rawCost, min: 0),
            _numberField(_processingPerRawUnit, l.processing, min: 0),
            _numberField(_packagingPerProduct, l.packaging, min: 0),
            _numberField(_transport, l.transport, min: 0),
            _numberField(_otherCosts, l.other, min: 0),
            const SizedBox(height: 8),
            Text(l.sales, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _numberField(_sellingPrice, l.price, min: 0),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.calculate_outlined),
              label: Text(l.calculate),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.result, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _result(l.raw, _rawName.text.isEmpty ? l.raw : _rawName.text),
                    _result(l.product, _productName.text.isEmpty ? l.product : _productName.text),
                    _result(l.output, outputQty.toStringAsFixed(2)),
                    const Divider(),
                    _result(l.rawProcessingCost, _money(rawCosts)),
                    _result(l.packagingCost, _money(packagingCosts)),
                    _result(l.transport, _money(estimate.transportCost)),
                    _result(l.other, _money(estimate.otherCosts)),
                    _result(l.total, _money(totalCosts), emphasized: true),
                    _result(
                      l.unit,
                      costPerProduct != null
                          ? _money(costPerProduct)
                          : l.unitUnavailable,
                    ),
                    _result(l.revenue, _money(revenue)),
                    _result(l.profit, _money(profit), emphasized: true),
                    _result(
                      l.margin,
                      margin != null
                          ? '${margin.toStringAsFixed(1)}%'
                          : l.marginUnavailable,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.warning,
                      style: const TextStyle(fontSize: 12),
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

  double _number(TextEditingController controller) =>
      _parseAmount(controller.text) ?? 0;
}
