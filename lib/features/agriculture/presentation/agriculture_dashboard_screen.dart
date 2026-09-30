import 'package:flutter/material.dart';
import '../../../services/agriculture_dashboard_service.dart';
import '../../../services/agriculture/agriculture_production_intelligence_service.dart';

class AurenAgricultureDashboardScreen extends StatefulWidget {
  const AurenAgricultureDashboardScreen({super.key});
  @override
  State<AurenAgricultureDashboardScreen> createState() => _AurenAgricultureDashboardScreenState();
}
class _AurenAgricultureDashboardScreenState extends State<AurenAgricultureDashboardScreen> {
  final _service = AgricultureDashboardService();
  final _productionService = AgricultureProductionIntelligenceService();
  final _crop = TextEditingController(text: 'Sorghum');
  final _iso3 = TextEditingController();
  Map<String, dynamic>? data;
  Map<String, dynamic>? backtest;
  Object? error;
  bool loading = false;

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final crop = _crop.text.trim().isEmpty ? 'Sorghum' : _crop.text.trim();
      final iso3 = _iso3.text.trim().toUpperCase();
      final result = await _service.load(crop: crop, iso3: iso3);
      Map<String, dynamic>? evaluated;
      try {
        evaluated = await _productionService.forecastBacktest(iso3: iso3, item: crop);
      } catch (_) {
        evaluated = null;
      }
      if (mounted) setState(() { data = result; backtest = evaluated; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e; loading = false; });
    }
  }
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _crop.dispose(); _iso3.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final snapshot = data?['globalLocalMarket'] is Map ? Map<String, dynamic>.from(data!['globalLocalMarket'] as Map) : const <String, dynamic>{};
    final readiness = data?['readiness'] is Map ? Map<String, dynamic>.from(data!['readiness'] as Map) : const <String, dynamic>{};
    final snapshotFx = snapshot['fx'] is Map ? Map<String, dynamic>.from(snapshot['fx'] as Map) : const <String, dynamic>{};
    final countries = snapshot['countries'] is List ? List<dynamic>.from(snapshot['countries'] as List) : const <dynamic>[];
    final producer = data?['producer'] is Map ? Map<String, dynamic>.from(data!['producer'] as Map) : const <String, dynamic>{};
    final latest = producer['latest'] is Map ? Map<String, dynamic>.from(producer['latest'] as Map) : const <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Agriculture Intelligence')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('🌱 Agriculture Market', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Global crop suitability, producer prices and local market intelligence.'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _crop, decoration: const InputDecoration(labelText: 'Crop', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              SizedBox(width: 90, child: TextField(controller: _iso3, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'ISO3', hintText: 'ALL', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: loading ? null : _load, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh), label: Text(loading ? 'Loading…' : 'Update market data')),
            if (error != null) ...[const SizedBox(height: 12), Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('Could not load agriculture data: $error')))],
            const SizedBox(height: 16),
            _metricGrid(context, [
              ('Countries', '${snapshot['countriesCovered'] ?? 0}'),
              ('Markets', '${snapshot['marketsCovered'] ?? 0}'),
              ('Price rows', '${snapshot['totalRows'] ?? 0}'),
              ('USD/t coverage', '${snapshot['conversionCoveragePct'] ?? 0}%'),
            ]),
            const SizedBox(height: 14),
            Card(child: ListTile(leading: const Icon(Icons.agriculture_outlined), title: const Text('Latest producer price'), subtitle: Text(latest.isEmpty ? 'No cached FAOSTAT producer observation yet.' : '${latest['priceUSDTonne'] ?? '—'} USD/tonne • ${latest['date'] ?? ''}'))),
            const SizedBox(height: 10),
            Card(child: ListTile(leading: Icon(readiness['faostatFxConfigured'] == true ? Icons.currency_exchange : Icons.currency_exchange_outlined), title: const Text('FAOSTAT exchange-rate bridge'), subtitle: Text(readiness['faostatFxConfigured'] == true ? 'Official FX bridge configured; USD/tonne conversion uses cached FAOSTAT rates when available.' : 'FX bridge code ready; configure the official FAOSTAT export endpoint to enable conversion.'))),
            const SizedBox(height: 10),
            _gaezCard(context, data?['gaez']),
            const SizedBox(height: 10),
            _baselineEvaluationCard(context),

            const SizedBox(height: 10),
            Card(child: ListTile(leading: Icon(readiness['fpmaLiveFeedConfigured'] == true ? Icons.cloud_done_outlined : Icons.cloud_off_outlined), title: const Text('FPMA local-market feed'), subtitle: Text(readiness['fpmaLiveFeedConfigured'] == true ? 'Configured' : 'Adapter ready; official export URL still needs configuration.'))),
            const SizedBox(height: 16),
            Text('Countries covered', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (countries.isEmpty)
              const Card(child: ListTile(title: Text('No local-market rows cached'), subtitle: Text('Run the official FPMA ingestion when its export is configured.')))
            else
              ...countries.take(40).map((raw) {
                final c = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
                return Card(child: ListTile(leading: const Icon(Icons.public), title: Text('${c['countryName'] ?? c['iso3'] ?? 'Unknown'}'), subtitle: Text('${c['markets'] ?? 0} markets • ${c['rows'] ?? 0} rows • ${c['latestNativePrice'] ?? '—'} ${c['latestCurrency'] ?? ''} ${c['latestUnit'] ?? ''}')));
              }),
          ],
        ),
      ),
    );
  }

  Widget _baselineEvaluationCard(BuildContext context) {
    final raw = backtest;
    final comparison = raw?['modelComparison'] is List
        ? List<dynamic>.from(raw!['modelComparison'] as List)
        : const <dynamic>[];
    final selected = raw?['selectedBaseline'] is Map
        ? Map<String, dynamic>.from(raw!['selectedBaseline'] as Map)
        : const <String, dynamic>{};
    final folds = raw?['folds'] ?? 0;

    if (raw == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.analytics_outlined),
          title: Text('Forecast baseline evaluation'),
          subtitle: Text('Backtesting data is not available for this crop/country yet.'),
        ),
      );
    }

    String metric(dynamic value) => value == null ? '—' : value.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.analytics_outlined),
            const SizedBox(width: 8),
            const Expanded(child: Text('Forecast baseline evaluation', style: TextStyle(fontWeight: FontWeight.bold))),
            Text('$folds folds'),
          ]),
          const SizedBox(height: 8),
          Text(selected.isEmpty
              ? 'No baseline selected from the available backtest.'
              : 'Selected baseline: ${selected['method'] ?? '—'}'),
          if (comparison.isNotEmpty) ...[
            const Divider(height: 20),
            ...comparison.map((rawModel) {
              final model = rawModel is Map
                  ? Map<String, dynamic>.from(rawModel)
                  : const <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text('${model['method'] ?? 'Model'}')),
                  Text('MAE ${metric(model['mae'])}'),
                  const SizedBox(width: 10),
                  Text('RMSE ${metric(model['rmse'])}'),
                  const SizedBox(width: 10),
                  Text('MAPE ${metric(model['mapePct'])}%'),
                ]),
              );
            }),
          ],
          const SizedBox(height: 8),
          Text(
            'Metrics are walk-forward historical backtest diagnostics; they are not a guarantee of future accuracy.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }

  Widget _gaezCard(BuildContext context, dynamic raw) {
    final g = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final status = g['status'] ?? 'no_data';
    final rows = g['rows'] ?? 0;
    final countries = g['countriesCovered'] ?? 0;
    final metrics = g['metrics'] is Map ? Map<String, dynamic>.from(g['metrics'] as Map) : const <String, dynamic>{};
    final samples = metrics['sampleMetrics'] is List ? List<dynamic>.from(metrics['sampleMetrics'] as List) : const <dynamic>[];
    final first = samples.isNotEmpty && samples.first is Map
        ? Map<String, dynamic>.from(samples.first as Map)
        : const <String, dynamic>{};

    String show(dynamic v, String suffix) => v == null || v.toString().isEmpty ? '—' : '${v}${suffix}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(status == 'ok' ? Icons.verified_outlined : Icons.landscape_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('GAEZ v5 crop intelligence', style: TextStyle(fontWeight: FontWeight.bold))),
              Text('${rows} rows'),
            ]),
            const SizedBox(height: 6),
            Text(status == 'ok'
                ? '${countries} countries covered'
                : 'No imported GAEZ v5 rows for this crop yet.'),
            if (first.isNotEmpty) ...[
              const Divider(height: 20),
              _gaezMetricLine('Suitability class', show(first['suitabilityClass'], '')),
              _gaezMetricLine('Suitable land', show(first['suitableLandHa'], ' ha')),
              _gaezMetricLine('Attainable yield', show(first['attainableYield'], '')),
              _gaezMetricLine('Potential production', show(first['potentialProduction'], '')),
              if (first['country'] != null || first['crop'] != null)
                Text('${first['country'] ?? '—'} • ${first['crop'] ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
            ] else if (status == 'ok')
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('GAEZ rows are available, but metric field names were not present in the imported sample.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _gaezMetricLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
  Widget _metricGrid(BuildContext context, List<(String, String)> values) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.3,
    children: values.map((v) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v.$2, style: Theme.of(context).textTheme.titleLarge), Text(v.$1)])))).toList(),
  );
}
