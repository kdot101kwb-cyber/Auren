import '../models/intent_context.dart';
import '../models/intent_result.dart';
import '../models/intent_entity.dart';
import 'intent_resolver.dart';

class RuleBasedIntentResolver implements IntentResolver {
  const RuleBasedIntentResolver();

  static const _countries = <String, String>{
    'sudan': 'SD',
    'السودان': 'SD',
    'china': 'CN',
    'الصين': 'CN',
    'egypt': 'EG',
    'مصر': 'EG',
    'turkey': 'TR',
    'تركيا': 'TR',
    'kenya': 'KE',
    'كندا': 'CA',
    'canada': 'CA',
    'usa': 'US',
    'united states': 'US',
    'america': 'US',
    'أمريكا': 'US',
    'uk': 'GB',
    'united kingdom': 'GB',
    'britain': 'GB',
    'بريطانيا': 'GB',
  };

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

    final supplierTerms = [
      'supplier', 'wholesaler', 'factory', 'manufacturer',
      'مورد', 'مصنع', 'جملة', 'شركة توريد',
    ];
    final productTerms = [
      'product', 'buy', 'purchase', 'منتج', 'شراء', 'عايز', 'اريد',
    ];

    final wantsSupplier = supplierTerms.any(input.contains);
    final wantsProduct = productTerms.any(input.contains);
    final countryEntities = _countries.entries
        .where((entry) => input.contains(entry.key))
        .map((entry) => IntentEntity(
              type: IntentEntityType.country,
              value: entry.value,
              confidence: .98,
              metadata: {'name': entry.key},
            ))
        .toList();

    final entities = <IntentEntity>[
      ...countryEntities,
    ];

    if (wantsSupplier) {
      entities.add(
        IntentEntity(
          type: IntentEntityType.supplier,
          value: input,
          confidence: .8,
          metadata: {
            'scope': countryEntities.isEmpty ? 'global' : 'country',
            if (countryEntities.isNotEmpty)
              'countryCode': countryEntities.first.value,
          },
        ),
      );

      return IntentResult(
        intentId: 'supplier.find',
        confidence: wantsProduct ? .94 : .9,
        candidateActionIds: const ['supplier.workflow'],
        entities: entities,
      );
    }

    if (wantsProduct) {
      return IntentResult(
        intentId: 'product.find',
        confidence: .78,
        candidateActionIds: const [],
        entities: [
          ...entities,
          IntentEntity(
            type: IntentEntityType.product,
            value: input,
            confidence: .7,
            metadata: {
              'scope': countryEntities.isEmpty ? 'global' : 'country',
              if (countryEntities.isNotEmpty)
                'countryCode': countryEntities.first.value,
            },
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