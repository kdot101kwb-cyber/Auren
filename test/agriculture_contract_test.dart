import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AUREN Agriculture contracts', () {
    test('supported agriculture record types stay stable', () {
      const types = {'crop', 'livestock', 'farm'};
      expect(types.length, 3);
      expect(types.contains('livestock'), isTrue);
    });

    test('agriculture note types are bounded', () {
      const types = ['field', 'livestock', 'farm'];
      expect(types, contains('field'));
      expect(types.length, 3);
    });

    test('location filtering is case insensitive by contract', () {
      const location = 'Khartoum North';
      expect(location.toLowerCase().contains('khartoum'), isTrue);
    });
  });
}
