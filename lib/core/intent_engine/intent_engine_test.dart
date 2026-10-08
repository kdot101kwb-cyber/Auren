import 'package:flutter_test/flutter_test.dart';
import 'intent_engine.dart';
import 'models/intent_context.dart';
import 'resolver/rule_based_intent_resolver.dart';

void main() {
  test('resolves Sudanese supplier request into supplier workflow candidate', () {
    const engine = IntentEngine(RuleBasedIntentResolver());
    final result = engine.resolve(const IntentContext(
      userId: 'test-user',
      input: 'عايز مورد ملابس',
      locale: 'ar',
    ));

    expect(result.intentId, 'supplier.find');
    expect(result.candidateActionIds, contains('supplier.workflow'));
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