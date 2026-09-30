import 'package:flutter/material.dart';

class AgricultureForecastSummaryCard extends StatelessWidget {
  final Map<String, dynamic> bundle;
  const AgricultureForecastSummaryCard({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    final rows = (bundle['revenueForecast'] as List? ?? const []);
    final first = rows.isEmpty ? null : Map<String, dynamic>.from(rows.first as Map);
    final last = rows.isEmpty ? null : Map<String, dynamic>.from(rows.last as Map);
    final status = (bundle['profitabilityStatus'] ?? 'needs_sourced_price_and_opex').toString();

    String v(dynamic x) => x == null ? '—' : x.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Agriculture Forecast', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _row(context, 'First forecast production', v(first?['predictedProduction'])),
          _row(context, 'First forecast yield', v(first?['predictedYield'])),
          _row(context, 'First forecast area', v(first?['predictedArea'])),
          _row(context, 'First forecast revenue', v(first?['revenue'])),
          _row(context, 'First forecast profit', v(first?['profit'])),
          const Divider(height: 24),
          _row(context, 'Final forecast year', v(last?['year'])),
          _row(context, 'Final production', v(last?['predictedProduction'])),
          _row(context, 'Final revenue', v(last?['revenue'])),
          _row(context, 'Final profit', v(last?['profit'])),
          const SizedBox(height: 10),
          Text(
            status == 'calculated'
                ? 'Revenue and profit use available sourced market price and explicit OPEX evidence.'
                : 'Revenue/profit remain incomplete until compatible sourced price and OPEX evidence are available.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
    ]),
  );
}
