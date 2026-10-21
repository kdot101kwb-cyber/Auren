import 'package:shared_preferences/shared_preferences.dart';
import 'trip_itinerary_service.dart';
import 'uid_scoped_json_list_store.dart';

class AurenTripItineraryStore {
  AurenTripItineraryStore({SharedPreferences? preferences}) : _store = AurenUidScopedJsonListStore<AurenTripStop>(keyPrefix: 'auren_trip_itinerary_v1_', preferences: preferences);
  final AurenUidScopedJsonListStore<AurenTripStop> _store;
}
