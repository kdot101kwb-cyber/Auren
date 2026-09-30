import 'package:flutter/material.dart';

class ProductionIntelligenceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onForecast;
  final VoidCallback? onScenario;
  const ProductionIntelligenceCard({super.key, required this.data, this.onForecast, this.onScenario});

  @override
  Widget build(BuildContext context) {
    final production = Map<String, dynamic>.from(data['production'] ?? const {});
    final latest = Map<String, dynamic>.from(production['latest'] ?? const {});
    final linkage = Map<String, dynamic>.from(data['linkage'] ?? const {});
    final growth = production['growthPct'];
    String value(dynamic v) => v == null ? '—' : v.toString();
    final growthText = growth == null ? '—' : growth.toString() + '%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Production Intelligence', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 12, children: [
            _Metric(label: 'Latest production', value: value(latest['production'])),
            _Metric(label: 'Yield', value: value(latest['yieldValue'])),
            _Metric(label: 'Area', value: value(latest['area'])),
            _Metric(label: 'Growth', value: growthText),
          ]),
          const SizedBox(height: 16),
          Text('Data links', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _LinkRow('GAEZ v5', linkage['productionToGaez'] == true),
          _LinkRow('Local prices', linkage['productionToLocalPrice'] == true),
          _LinkRow('Global prices', linkage['productionToGlobalPrice'] == true),
          _LinkRow('Financial feasibility', linkage['readyForFinancialFeasibility'] == true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: onForecast, child: const Text('Forecast'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: onScenario, child: const Text('Scenario'))),
          ]),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ]),
  );
}

class _LinkRow extends StatelessWidget {
  final String label;
  final bool connected;
  const _LinkRow(this.label, this.connected);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(connected ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 18),
      const SizedBox(width: 8),
      Text(label),
    ]),
  );
}
