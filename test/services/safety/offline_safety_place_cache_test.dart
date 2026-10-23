import 'package:auren/services/safety/offline_safety_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cached safety place parsing tolerates malformed field types', () {
    final place = AurenSafetyPlace.fromJson({
      'id': 17,
      'name': 'Community clinic',
      'type': null,
      'city': 42,
      'country': false,
    });

    expect(place.id, '17');
    expect(place.name, 'Community clinic');
    expect(place.type, 'emergency');
    expect(place.city, '42');
    expect(place.country, 'false');
  });

  test('cached safety place parsing supplies safe defaults for missing fields', () {
    final place = AurenSafetyPlace.fromJson(const <String, dynamic>{});

    expect(place.id, isEmpty);
    expect(place.name, isEmpty);
    expect(place.type, 'emergency');
    expect(place.city, isEmpty);
    expect(place.country, isEmpty);
  });
}
