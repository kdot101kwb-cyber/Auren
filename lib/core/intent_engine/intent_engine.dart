import 'models/intent_context.dart';
import 'models/intent_result.dart';
import 'resolver/intent_resolver.dart';

class IntentEngine {
  final IntentResolver resolver;
  const IntentEngine(this.resolver);

  IntentResult resolve(IntentContext context) {
    final result = resolver.resolve(context);
    if (result.confidence < .5) {
      return IntentResult(
        intentId: 'unknown',
        confidence: result.confidence,
        candidateActionIds: const [],
        entities: result.entities,
        ambiguous: true,
      );
    }
    return result;
  }
}