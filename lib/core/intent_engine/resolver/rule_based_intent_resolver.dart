import '../models/intent_context.dart';
import '../models/intent_result.dart';
import '../models/intent_entity.dart';
import 'intent_resolver.dart';

class RuleBasedIntentResolver implements IntentResolver {
  const RuleBasedIntentResolver();

  @override
  IntentResult resolve(IntentContext context) {
    final input = context.input.trim().toLowerCase();

    if (input.isEmpty) {
      return const IntentResult(
        intentId: 'unknown',
        confidence: 0,
        candidateActionIds: [],
        ambiguous: true,
      );
    }

    final supplierTerms = ['supplier', 'wholesaler', 'factory', 'مورد', 'مصنع', 'جملة'];
    final productTerms = ['product', 'buy', 'purchase', 'منتج', 'شراء', 'عايز', 'اريد'];

    final wantsSupplier = supplierTerms.any(input.contains);
    final wantsProduct = productTerms.any(input.contains);

    if (wantsSupplier) {
      return IntentResult(
        intentId: 'supplier.find',
        confidence: wantsProduct ? .94 : .9,
        candidateActionIds: const ['supplier.workflow'],
        entities: [
          IntentEntity(
            type: IntentEntityType.supplier,
            value: input,
            confidence: .8,
          ),
        ],
      );
    }

    if (wantsProduct) {
      return IntentResult(
        intentId: 'product.find',
        confidence: .78,
        candidateActionIds: const ['product.search'],
        entities: [
          IntentEntity(
            type: IntentEntityType.product,
            value: input,
            confidence: .7,
          ),
        ],
      );
    }

    return const IntentResult(
      intentId: 'unknown',
      confidence: .2,
      candidateActionIds: [],
      ambiguous: true,
    );
  }
}