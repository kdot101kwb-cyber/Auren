import 'package:flutter_test/flutter_test.dart';
import 'intent_engine.dart';
import 'models/intent_context.dart';
import 'models/intent_entity.dart';
import 'resolver/rule_based_intent_resolver.dart';

void main() {
  test('resolves Sudanese supplier request without making Sudan a special path', () {
    const engine = IntentEngine(RuleBasedIntentResolver());
    final result = engine.resolve(const IntentContext(
      userId: 'test-user',
      input: 'عايز مورد ملابس في السودان',
      locale: 'ar',
      countryCode: 'SD',
      currencyCode: 'SDG',
    ));

    expect(result.intentId, 'supplier.find');
    expect(result.candidateActionIds, contains('supplier.workflow'));
    expect(result.ambiguous, isFalse);
    expect(
      result.entities.any(
        (entity) =>
            entity is IntentEntity &&
            entity.type == IntentEntityType.country &&
            entity.value == 'SD',
      ),
      isTrue,
    );
  });

  test('resolves China with the same global country model', () {
    const engine = IntentEngine(RuleBasedIntentResolver());
    final result = engine.resolve(const IntentContext(
      userId: 'test-user',
      input: 'find a clothing supplier in China',
      locale: 'en',
      countryCode: 'CN',
      currencyCode: 'CNY',
    ));

    expect(result.intentId, 'supplier.find');
    expect(result.ambiguous, isFalse);
    expect(
      result.entities.any(
        (entity) =>
            entity is IntentEntity &&
            entity.type == IntentEntityType.country &&
            entity.value == 'CN',
      ),
      isTrue,
    );
  });

  test('keeps product discovery global without inventing an execution action', () {
    const engine = IntentEngine(RuleBasedIntentResolver());
    final result = engine.resolve(const IntentContext(
      userId: 'test-user',
      input: 'find clothing products',
      locale: 'en',
    ));

    expect(result.intentId, 'product.find');
    expect(result.candidateActionIds, isEmpty);
    expect(result.ambiguous, isFalse);
  });

  test('does not invent an action for unknown input', () {
    const engine = IntentEngine(RuleBasedIntentResolver());
    final result = engine.resolve(const IntentContext(
      userId: 'test-user',
      input: 'something unrelated',
    ));

    expect(result.candidateActionIds, isEmpty);
    expect(result.ambiguous, isTrue);
  });
}
