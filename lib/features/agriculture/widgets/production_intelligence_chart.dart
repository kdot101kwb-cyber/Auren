import 'package:flutter/material.dart';
import '../../../services/agriculture/agriculture_production_intelligence_service.dart';

class ProductionIntelligenceChart extends StatelessWidget {
  final List<AgricultureProductionPoint> history;
  final List<AgricultureForecastPoint> forecast;

  const ProductionIntelligenceChart({
    super.key,
    required this.history,
    this.forecast = const [],
  });

  @override
  Widget build(BuildContext context) {
    final points = [...history, ...forecast.map((e) => AgricultureProductionPoint(
      iso3: '', country: '', item: '', year: e.year,
      production: e.predictedProduction,
    ))]..sort((a, b) => a.year.compareTo(b.year));

    if (points.isEmpty) {
      return const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No production trend data available'),
      ));
    }

    final maxValue = points.map((e) => e.production ?? 0).fold<double>(
      0, (a, b) => a > b ? a : b,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Production Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _TrendPainter(points: points, maxValue: maxValue),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            forecast.isEmpty ? 'Historical production' : 'Historical + baseline forecast',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<AgricultureProductionPoint> points;
  final double maxValue;
  _TrendPainter({required this.points, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || maxValue <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final value = points[i].production ?? 0;
      final y = size.height - (value / maxValue) * (size.height - 12);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}
