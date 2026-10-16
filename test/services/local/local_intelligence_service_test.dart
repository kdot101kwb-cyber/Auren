import 'dart:async';

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

    test('matches country when only country is supplied', () {
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

    test('does not match when no location filter is supplied', () {
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

  group('AurenLocalIntelligenceService.combineLatest2', () {
    test('emits again when the second stream changes', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final firstPair = Completer<void>();
      final secondPair = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen((value) {
        values.add(value);
        if (values.length == 1 && !firstPair.isCompleted) firstPair.complete();
        if (values.length == 2 && !secondPair.isCompleted) secondPair.complete();
      });

      first.add(1);
      second.add('initial');
      await firstPair.future;
      second.add('updated');
      await secondPair.future;

      expect(values, [(1, 'initial'), (1, 'updated')]);

      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('waits until both streams have emitted', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen(values.add);

      first.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(values, isEmpty);

      second.add('ready');
      await Future<void>.delayed(Duration.zero);
      expect(values, [(1, 'ready')]);

      await subscription.cancel();
      await first.close();
      await second.close();
    });
  });
}
