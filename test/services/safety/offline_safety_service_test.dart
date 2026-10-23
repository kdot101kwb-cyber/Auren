import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/safety/offline_safety_service.dart';

void main() {
  test('validates geographic points including boundary coordinates', () {
    expect(AurenOfflineSafetyService.isValidPoint({'lat': 0, 'lng': 0}), isTrue);
    expect(AurenOfflineSafetyService.isValidPoint({'latitude': 90, 'longitude': 180}), isTrue);
    expect(AurenOfflineSafetyService.isValidPoint({'lat': 91, 'lng': 0}), isFalse);
    expect(AurenOfflineSafetyService.isValidPoint({'lat': 0, 'lng': 181}), isFalse);
    expect(AurenOfflineSafetyService.isValidPoint({'lat': double.nan, 'lng': 1}), isFalse);
    expect(AurenOfflineSafetyService.isValidPoint({'lat': '0', 'lng': 1}), isFalse);
  });

  test('cached routes are limited to the current owner and valid coordinates', () {
    final rows = AurenOfflineSafetyService.sanitizeCachedRoutesForTest([
      {
        'id': 'owned',
        'ownerId': 'user-a',
        'name': 'Safe route',
        'points': [
          {'lat': 15.5, 'lng': 32.5},
          {'lat': 15.6, 'lng': 32.6},
        ],
      },
      {
        'id': 'other-user',
        'ownerId': 'user-b',
        'name': 'Private route',
        'points': [
          {'lat': 15.5, 'lng': 32.5},
          {'lat': 15.6, 'lng': 32.6},
        ],
      },
      {
        'id': 'bad-points',
        'ownerId': 'user-a',
        'name': 'Invalid route',
        'points': [
          {'lat': 150, 'lng': 32},
          {'lat': 15, 'lng': 32},
        ],
      },
    ], 'user-a');

    expect(rows, hasLength(1));
    expect(rows.single['id'], 'owned');
  });
}
