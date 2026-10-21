import 'package:flutter/foundation.dart';

enum AurenUtilityKind { electricity, water, gas, other }

@immutable
class AurenUtilityReading {
  const AurenUtilityReading({required this.id, required this.meterId, required this.kind, required this.value, required this.unit, required this.recordedAt, this.label = '', this.note = ''});
  final String id;
  final String meterId;
  final AurenUtilityKind kind;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final String label;
  final String note;
  String? validate() {
    if (id.trim().isEmpty || meterId.trim().isEmpty || meterId.trim().length > 80) return 'Reading and meter ids are required.';
    if (label.trim().isEmpty || label.trim().length > 100 || unit.trim().isEmpty || unit.trim().length > 16) return 'Meter label or unit is invalid.';
    if (!value.isFinite || value < 0) return 'Reading must be finite and non-negative.';
    if (note.length > 500) return 'Note is too long.';
    return null;
  }
}

class AurenHomeUtilityLedger {
  const AurenHomeUtilityLedger._();
  static List<AurenUtilityReading> ordered(Iterable<AurenUtilityReading> input) {
    final result = input.toList();
    result.sort((a, b) { final m = a.meterId.compareTo(b.meterId); if (m != 0) return m; final d = a.recordedAt.compareTo(b.recordedAt); return d != 0 ? d : a.id.compareTo(b.id); });
    return List.unmodifiable(result);
  }
  static double? latestUsage(Iterable<AurenUtilityReading> input, String meterId) {
    final rows = ordered(input).where((v) => v.meterId == meterId).toList();
    if (rows.length < 2) return null;
    final a = rows[rows.length - 2]; final b = rows.last;
    if (b.value < a.value || a.unit != b.unit || a.kind != b.kind) return null;
    return b.value - a.value;
  }
  static String? validateSeries(Iterable<AurenUtilityReading> input) {
    final values = input.toList();
    for (final value in values) { final issue = value.validate(); if (issue != null) return issue; }
    final rows = ordered(values); final byMeter = <String, List<AurenUtilityReading>>{};
    for (final row in rows) { byMeter.putIfAbsent(row.meterId, () => <AurenUtilityReading>[]).add(row); }
    for (final series in byMeter.values) {
      for (var i = 1; i < series.length; i++) {
        final a = series[i - 1]; final b = series[i];
        if (a.recordedAt.isAtSameMomentAs(b.recordedAt)) return 'Duplicate reading time for a meter.';
        if (a.kind != b.kind || a.unit != b.unit) return 'Meter type and unit must remain consistent.';
        if (b.value < a.value) return 'Cumulative reading cannot decrease.';
      }
    }
    return null;
  }
}