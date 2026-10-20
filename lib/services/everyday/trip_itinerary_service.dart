import 'package:flutter/foundation.dart';

/// A planned stop in a user's itinerary. This is planning data only:
/// it does not book transport, accommodation, tickets, or activities.
@immutable
class AurenTripStop {
  final String id;
  final String title;
  final String location;
  final DateTime? plannedAt;
  final String notes;
  final bool completed;

  const AurenTripStop({
    required this.id,
    required this.title,
    this.location = '',
    this.plannedAt,
    this.notes = '',
    this.completed = false,
  });

  String? validate() {
    if (id.trim().isEmpty) return 'Stop id is required.';
    if (title.trim().isEmpty || title.trim().length > 120) {
      return 'Stop title must contain 1–120 characters.';
    }
    if (location.length > 200) return 'Location is too long.';
    if (notes.length > 1000) return 'Notes are too long.';
    return null;
  }

  AurenTripStop copyWith({bool? completed}) => AurenTripStop(
        id: id,
        title: title,
        location: location,
        plannedAt: plannedAt,
        notes: notes,
        completed: completed ?? this.completed,
      );
}

/// Deterministic itinerary helpers. Invalid stops are excluded from derived
/// lists so malformed data cannot appear as actionable checklist items.
class AurenTripItineraryPlanner {
  const AurenTripItineraryPlanner._();

  static List<AurenTripStop> orderedStops(Iterable<AurenTripStop> stops) {
    final valid = stops.where((stop) => stop.validate() == null).toList();
    valid.sort((a, b) {
      if (a.plannedAt == null && b.plannedAt == null) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      if (a.plannedAt == null) return 1;
      if (b.plannedAt == null) return -1;
      final byTime = a.plannedAt!.compareTo(b.plannedAt!);
      return byTime != 0
          ? byTime
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return List.unmodifiable(valid);
  }

  static List<AurenTripStop> remainingStops(Iterable<AurenTripStop> stops) =>
      List.unmodifiable(orderedStops(stops).where((stop) => !stop.completed));

  static double completionRatio(Iterable<AurenTripStop> stops) {
    final valid = orderedStops(stops);
    if (valid.isEmpty) return 0;
    return valid.where((stop) => stop.completed).length / valid.length;
  }
}
