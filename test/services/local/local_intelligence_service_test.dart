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
    test('emits again when either stream changes', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final pairCountReached = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen((value) {
        values.add(value);
        if (values.length == 3 && !pairCountReached.isCompleted) {
          pairCountReached.complete();
        }
      });

      first.add(1);
      second.add('initial');
      await Future<void>.delayed(Duration.zero);
      first.add(2);
      await Future<void>.delayed(Duration.zero);
      second.add('updated');
      await pairCountReached.future;

      expect(values, [(1, 'initial'), (2, 'initial'), (2, 'updated')]);

      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('cancels both source subscriptions when cancelled', () async {
      var firstCancelled = false;
      var secondCancelled = false;
      final first = StreamController<int>(onCancel: () {
        firstCancelled = true;
      });
      final second = StreamController<String>(onCancel: () {
        secondCancelled = true;
      });
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen((_) {});

      await subscription.cancel();

      expect(firstCancelled, isTrue);
      expect(secondCancelled, isTrue);
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

    test('cancels the other source when one completes empty', () async {
      final first = Stream<int>.empty();
      var secondCancelled = false;
      final second = StreamController<String>(onCancel: () {
        secondCancelled = true;
      });
      var completed = false;
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first,
        second.stream,
      ).listen((_) {}, onDone: () => completed = true);

      await Future<void>.delayed(Duration.zero);
      expect(completed, isTrue);
      expect(secondCancelled, isTrue);

      await subscription.cancel();
      await second.close();
    });

    test('closes after both sources finish', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final done = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen(values.add, onDone: done.complete);

      first.add(3);
      second.add('ready');
      await Future<void>.delayed(Duration.zero);
      await first.close();
      await second.close();
      await done.future;

      expect(values, [(3, 'ready')]);
      await subscription.cancel();
    });

    test('keeps the last value from a source that completes', () async {
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final reached = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        Stream<int>.value(7),
        second.stream,
      ).listen((value) {
        values.add(value);
        if (values.length == 2 && !reached.isCompleted) reached.complete();
      });

      second.add('first');
      await Future<void>.delayed(Duration.zero);
      second.add('second');
      await reached.future;

      expect(values, [(7, 'first'), (7, 'second')]);
      await subscription.cancel();
      await second.close();
    });

    test('forwards errors from a source without closing immediately', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final receivedError = Completer<Object>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen((_) {}, onError: (Object error) {
        if (!receivedError.isCompleted) receivedError.complete(error);
      });

      first.addError(StateError('source failed'));
      expect(await receivedError.future, isA<StateError>());

      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('cancels the first source when the second completes empty', () async {
      var firstCancelled = false;
      final first = StreamController<int>(onCancel: () {
        firstCancelled = true;
      });
      var completed = false;
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        Stream<String>.empty(),
      ).listen((_) {}, onDone: () => completed = true);

      await Future<void>.delayed(Duration.zero);

      expect(completed, isTrue);
      expect(firstCancelled, isTrue);
      await subscription.cancel();
      await first.close();
    });

    test('continues emitting after a source error', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final receivedError = Completer<void>();
      final reachedValue = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen(
        (value) {
          values.add(value);
          if (!reachedValue.isCompleted) reachedValue.complete();
        },
        onError: (Object error) {
          if (!receivedError.isCompleted) receivedError.complete();
        },
      );

      first.addError(StateError('temporary'));
      await receivedError.future;
      first.add(9);
      second.add('recovered');
      await reachedValue.future;

      expect(values, [(9, 'recovered')]);
      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('retains latest values after a source error', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <(int, String)>[];
      final receivedError = Completer<void>();
      final updatedPair = Completer<void>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen(
        (value) {
          values.add(value);
          if (values.length == 2 && !updatedPair.isCompleted) {
            updatedPair.complete();
          }
        },
        onError: (Object error) {
          if (!receivedError.isCompleted) receivedError.complete();
        },
      );

      first.add(4);
      second.add('initial');
      await Future<void>.delayed(Duration.zero);
      first.addError(StateError('temporary'));
      await receivedError.future;
      second.add('updated');
      await updatedPair.future;

      expect(values, [(4, 'initial'), (4, 'updated')]);

      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('forwards errors before both sources have emitted', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final receivedError = Completer<void>();
      final reachedPair = Completer<void>();
      final values = <(int, String)>[];
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen(
        values.add,
        onError: (Object error) {
          if (!receivedError.isCompleted) receivedError.complete();
        },
      );

      first.addError(StateError('before initial value'));
      await receivedError.future;
      first.add(5);
      second.add('ready');
      await Future<void>.delayed(Duration.zero);
      if (values.isNotEmpty && !reachedPair.isCompleted) reachedPair.complete();
      // Wait for delivery without depending on the source error closing the stream.
      if (!reachedPair.isCompleted) {
        first.add(6);
        await Future<void>.delayed(Duration.zero);
      }

      expect(values, isNotEmpty);
      expect(values.first, (5, 'ready'));

      await subscription.cancel();
      await first.close();
      await second.close();
    });

    test('forwards errors from the second source too', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final receivedError = Completer<Object>();
      final subscription = AurenLocalIntelligenceService.combineLatest2(
        first.stream,
        second.stream,
      ).listen((_) {}, onError: (Object error) {
        if (!receivedError.isCompleted) receivedError.complete(error);
      });

      second.addError(ArgumentError('second source failed'));
      expect(await receivedError.future, isA<ArgumentError>());

      await subscription.cancel();
      await first.close();
      await second.close();
    });
  });
}
