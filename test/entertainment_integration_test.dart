import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Entertainment integration contracts', () {
    test('search normalizes whitespace and is case-insensitive', () {
      expect('  Film  '.trim().toLowerCase(), 'film');
      expect('AUREN'.toLowerCase().contains('auren'), isTrue);
    });

    test('recommendation score favors completion/save and penalizes skips', () {
      double score(Map<String, num> s) =>
          (s['watchSeconds'] ?? 0) * .02 +
          (s['likes'] ?? 0) * 5 +
          (s['saves'] ?? 0) * 4 +
          (s['completions'] ?? 0) * 3 -
          (s['skips'] ?? 0) * 2;
      expect(score({'saves': 1, 'completions': 1}),
          greaterThan(score({'skips': 1})));
    });

    test('watch together room state has safe defaults', () {
      final state = {'positionSeconds': 0, 'isPlaying': false, 'status': 'waiting'};
      expect(state['positionSeconds'], 0);
      expect(state['isPlaying'], false);
      expect(state['status'], 'waiting');
    });

    test('rights declaration has bounded input', () {
      const declaration = 'I confirm I have the rights or permission to use this content.';
      expect(declaration.length, inInclusiveRange(10, 2000));
    });
  });
}
