import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/trip_itinerary_service.dart';

void main() {
  test('validates required stop identity and title', () {
    expect(const AurenTripStop(id: '', title: 'Stop').validate(), isNotNull);
    expect(const AurenTripStop(id: '1', title: '').validate(), isNotNull);
    expect(const AurenTripStop(id: '1', title: 'Museum').validate(), isNull);
  });

  test('orders scheduled stops before unscheduled stops', () {
    final early = DateTime.utc(2026, 11, 1, 8);
    final late = DateTime.utc(2026, 11, 1, 14);
    final result = AurenTripItineraryPlanner.orderedStops([
      const AurenTripStop(id: 'none', title: 'Unscheduled'),
      AurenTripStop(id: 'late', title: 'Later', plannedAt: late),
      AurenTripStop(id: 'early', title: 'Earlier', plannedAt: early),
    ]);
    expect(result.map((stop) => stop.id), ['early', 'late', 'none']);
  });

  test('computes completion ratio and excludes invalid stops', () {
    expect(AurenTripItineraryPlanner.completionRatio([]), 0);
    expect(AurenTripItineraryPlanner.completionRatio([
      const AurenTripStop(id: '1', title: 'Museum', completed: true),
      const AurenTripStop(id: '2', title: 'Market'),
      const AurenTripStop(id: '', title: 'Invalid', completed: true),
    ]), 0.5);
  });

  test('excludes all stops with duplicate IDs from itinerary and progress', () {
    final stops = [
      const AurenTripStop(id: 'duplicate', title: 'Old Town', completed: true),
      const AurenTripStop(id: 'duplicate', title: 'Museum'),
      const AurenTripStop(id: 'unique', title: 'Market'),
    ];

    expect(
      AurenTripItineraryPlanner.orderedStops(stops).map((stop) => stop.id),
      ['unique'],
    );
    expect(AurenTripItineraryPlanner.completionRatio(stops), 0);
    expect(AurenTripItineraryPlanner.remainingStops(stops).map((stop) => stop.id),
        ['unique']);
  });

  test('copyWith does not mutate the original stop', () {
    const stop = AurenTripStop(id: '1', title: 'Gallery');
    final completed = stop.copyWith(completed: true);
    expect(stop.completed, isFalse);
    expect(completed.completed, isTrue);
  });
}
