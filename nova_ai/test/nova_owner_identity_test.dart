import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/tasks/nova_owner_identity.dart';

void main() {
  group('hasNovaPasswordProvider', () {
    test('accepts an explicitly linked email/password provider', () {
      expect(hasNovaPasswordProvider(['google.com', 'password']), isTrue);
    });

    test('does not mistake a federated provider for email/password', () {
      expect(hasNovaPasswordProvider(['google.com', 'apple.com']), isFalse);
    });

    test('rejects anonymous-only and empty provider lists', () {
      expect(hasNovaPasswordProvider(['anonymous']), isFalse);
      expect(hasNovaPasswordProvider(const []), isFalse);
    });
  });

  group('matchesNovaOwnerEmail', () {
    test('matches case-insensitively after trimming', () {
      expect(matchesNovaOwnerEmail(' Owner@Example.com ', 'owner@example.com'), isTrue);
    });

    test('rejects missing, empty, or different account email', () {
      expect(matchesNovaOwnerEmail(null, 'owner@example.com'), isFalse);
      expect(matchesNovaOwnerEmail('', 'owner@example.com'), isFalse);
      expect(matchesNovaOwnerEmail('other@example.com', 'owner@example.com'), isFalse);
      expect(matchesNovaOwnerEmail('owner@example.com', ' '), isFalse);
    });
  });
}
