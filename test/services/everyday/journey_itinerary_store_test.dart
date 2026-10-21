import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/trip_itinerary_service.dart';
import 'package:auren/services/everyday/journey_itinerary_store.dart';
void main() {
 setUp(() => SharedPreferences.setMockInitialValues({}));
 AurenTripStop makeStop({String id = 'museum', String title = 'Museum', int day = 2}) => AurenTripStop(id: id, title: title, location: 'Khartoum', plannedAt: DateTime.now().add(Duration(days: day)));
 test('stores ordered itinerary records by UID', () async { final store = AurenTripItineraryStore(); await store.saveStop('user-a', makeStop(id: 'later', title: 'Later', day: 3)); await store.saveStop('user-a', makeStop(id: 'earlier', title: 'Earlier', day: 1)); expect((await store.loadStops('user-a')).map((v) => v.id), ['earlier', 'later']); expect(await store.loadStops('user-b'), isEmpty); });
 test('rejects blank UID and invalid stop', () async { final store = AurenTripItineraryStore(); await expectLater(store.loadStops(' '), throwsArgumentError); await expectLater(store.saveStop('user-a', makeStop(title: '')), throwsArgumentError); });
}
