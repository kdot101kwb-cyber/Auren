import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/local/local_intelligence_service.dart';

void main() {
  group('AurenLocalIntelligenceService.locationMatches', () {
    test('matches city case-insensitively when only city is supplied', () {
      expect(
        AurenLocalIntelligenceService.locationMatches(
          city: 'Khartoum',
          country: '',
          candidateCity: ' khartoum ',
          candidateCountry: '',
        ),
        isTrue,
      );
    });

    test('does not match a blank city when filtering by country only', () {
      expect(
        AurenLocalIntelligenceService.locationMatches(
          city: '',
          country: 'Sudan',
          candidateCity: '',
          candidateCountry: 'Sudan',
        ),
        isTrue,
      );
    });

    test('requires both supplied city and country to match', () {
      expect(
        AurenLocalIntelligenceService.locationMatches(
          city: 'Khartoum',
          country: 'Sudan',
          candidateCity: 'Khartoum',
          candidateCountry: '',
        ),
        isFalse,
      );
      expect(
        AurenLocalIntelligenceService.locationMatches(
          city: 'Khartoum',
          country: 'Sudan',
          candidateCity: 'Khartoum',
          candidateCountry: 'Sudan',
        ),
        isTrue,
      );
    });

    test('does not return matches when no location filter is supplied', () {
      expect(
        AurenLocalIntelligenceService.locationMatches(
          city: ' ',
          country: '',
          candidateCity: 'Khartoum',
          candidateCountry: 'Sudan',
        ),
        isFalse,
      );
    });
  });
}
